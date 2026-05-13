#!/usr/bin/env python3
import argparse
import math
import os
import re
import subprocess
from dataclasses import dataclass
from typing import List, Optional, Tuple


SIL_START_RE = re.compile(r"silence_start:\s*([0-9.]+)")
SIL_END_RE   = re.compile(r"silence_end:\s*([0-9.]+)\s*\|\s*silence_duration:\s*([0-9.]+)")


@dataclass
class Silence:
    start: float
    end: float
    duration: float


def run(cmd: List[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)


def detect_silences(
    infile: str,
    noise_db: float,
    min_silence: float,
) -> List[Silence]:
    # We only need analysis output; write nothing (-f null -)
    cmd = [
        "ffmpeg", "-hide_banner", "-nostats",
        "-i", infile,
        "-af", f"silencedetect=n={noise_db}dB:d={min_silence}",
        "-f", "null", "-"
    ]
    p = run(cmd)
    log = p.stderr.splitlines()

    silences: List[Silence] = []
    pending_start: Optional[float] = None

    for line in log:
        m1 = SIL_START_RE.search(line)
        if m1:
            pending_start = float(m1.group(1))
            continue
        m2 = SIL_END_RE.search(line)
        if m2 and pending_start is not None:
            end = float(m2.group(1))
            dur = float(m2.group(2))
            silences.append(Silence(start=pending_start, end=end, duration=dur))
            pending_start = None

    return silences


def pick_cut_time(
    target: float,
    silences: List[Silence],
    window: float,
) -> Optional[float]:
    """
    Pick a cut time near target within ±window seconds.
    Preference:
      1) If target is inside a silence interval, cut at target (best).
      2) Else cut at the nearest silence midpoint within window.
    """
    best: Optional[Tuple[float, float]] = None  # (score, cut_time)

    for s in silences:
        # If target is inside silence, perfect
        if s.start <= target <= s.end:
            return target

        mid = (s.start + s.end) / 2.0
        dist = abs(mid - target)
        if dist <= window:
            # score: distance first, then prefer longer silence a bit
            score = dist - 0.1 * min(s.duration, 5.0)
            if best is None or score < best[0]:
                best = (score, mid)

    return best[1] if best else None


def get_duration(infile: str) -> float:
    cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=nw=1:nk=1",
        infile
    ]
    p = run(cmd)
    if p.returncode != 0 or not p.stdout.strip():
        raise RuntimeError("ffprobe could not read duration.")
    return float(p.stdout.strip())


def build_split_points(
    duration: float,
    seg_len: float,
    silences: List[Silence],
    window: float,
) -> List[float]:
    points: List[float] = []
    t = seg_len
    while t < duration - 0.5:
        cut = pick_cut_time(t, silences, window)
        points.append(cut if cut is not None else t)
        t += seg_len

    # De-dup / ensure strictly increasing
    cleaned: List[float] = []
    last = 0.0
    for x in points:
        x = max(x, last + 0.01)
        if x < duration - 0.01:
            cleaned.append(x)
            last = x
    return cleaned


def ffmpeg_split(
    infile: str,
    out_pattern: str,
    split_points: List[float],
    reencode: bool,
    crf: int,
    preset: str,
):
    # FFmpeg segment muxer splits at keyframes; for accurate cuts we re-encode
    # and force keyframes at split points. segment_times expects comma-separated times. :contentReference[oaicite:2]{index=2}
    times = ",".join(f"{x:.3f}" for x in split_points)

    cmd = ["ffmpeg", "-hide_banner", "-y", "-i", infile]

    if reencode:
        cmd += [
            "-force_key_frames", times,
            "-c:v", "libx264", "-preset", preset, "-crf", str(crf),
            "-c:a", "aac", "-b:a", "192k",
        ]
    else:
        # Fast but may cut only on existing keyframes (cuts can drift)
        cmd += ["-c", "copy"]

    cmd += [
        "-map", "0",
        "-f", "segment",
        "-segment_times", times,
        "-reset_timestamps", "1",
        out_pattern
    ]

    p = subprocess.run(cmd)
    if p.returncode != 0:
        raise SystemExit(p.returncode)


def main():
    ap = argparse.ArgumentParser(description="Split video into ~10-min chunks at quiet moments.")
    ap.add_argument("input", help="input video file")
    ap.add_argument("-o", "--output", default="out_%03d.mp4", help="output pattern (default: out_%%03d.mp4)")
    ap.add_argument("--minutes", type=float, default=10.0, help="target segment length in minutes (default: 10)")
    ap.add_argument("--noise-db", type=float, default=-38.0, help="silence threshold in dB (default: -38)")
    ap.add_argument("--min-silence", type=float, default=0.6, help="minimum quiet duration (seconds) (default: 0.6)")
    ap.add_argument("--window", type=float, default=90.0, help="search window around each cut (seconds) (default: 90)")
    ap.add_argument("--no-reencode", action="store_true", help="stream copy (faster, less accurate cuts)")
    ap.add_argument("--crf", type=int, default=20, help="x264 CRF if re-encoding (default: 20)")
    ap.add_argument("--preset", default="veryfast", help="x264 preset (default: veryfast)")
    args = ap.parse_args()

    duration = get_duration(args.input)
    seg_len = args.minutes * 60.0

    silences = detect_silences(args.input, args.noise_db, args.min_silence)
    split_points = build_split_points(duration, seg_len, silences, args.window)

    if not split_points:
        print("No split points found (video too short?).")
        return

    print("Split points (s):", ", ".join(f"{t:.3f}" for t in split_points))
    ffmpeg_split(
        args.input,
        args.output,
        split_points,
        reencode=not args.no_reencode,
        crf=args.crf,
        preset=args.preset,
    )


if __name__ == "__main__":
    main()
