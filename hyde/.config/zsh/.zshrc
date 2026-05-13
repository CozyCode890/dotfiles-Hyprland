# Add user configurations here
# For HyDE to not touch your beloved configurations,
# we added a config file for you to customize HyDE before loading zshrc
# Edit $ZDOTDIR/.user.zsh to customize HyDE before loading zshrc

#  Plugins 
# oh-my-zsh plugins are loaded  in $ZDOTDIR/.user.zsh file, see the file for more information
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
zstyle ':omz:update' mode auto

#  Functions 
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

#  Environment 
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"

#  FZF 
export FZF_DEFAULT_COMMAND='find . \
  \( -path "./.*" \
     ! -path "./.config" \
     ! -path "./.config/*" \
     ! -path "./.local" \
     ! -path "./.local/*" \
  \) -prune -o -print 2>/dev/null'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_ALT_C_COMMAND='find . -type d \
  \( -path "./.*" \
     ! -path "./.config" \
     ! -path "./.config/*" \
     ! -path "./.local" \
     ! -path "./.local/*" \
  \) -prune -o -type d -print 2>/dev/null'

#  Pager 
export LESS="-FRSX"
export MANROFFOPT='-c'
alias less="env TERM=xterm less"
alias bat="env TERM=xterm bat"
export PAGER="env TERM=xterm less"
export BAT_PAGER="less -FRSX"
export MANPAGER="sh -c 'col -bx | env TERM=xterm bat -l man --style=plain,changes'"

#  Aliases 
# if [ -n "$KITTY_PID" ]; then
#   alias clear="printf '\033c'"
# fi

#  Aliases 
# Override aliases here in '$ZDOTDIR/.zshrc' (already set in .zshenv)
# # Helpful aliases
# alias c='clear'                                                        # clear terminal
# alias l='eza -lh --icons=auto'                                         # long list
# alias ls='eza -1 --icons=auto'                                         # short list
# alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
# alias ld='eza -lhD --icons=auto'                                       # long list dirs
# alias lt='eza --icons=auto --tree'                                     # list folder as tree
# alias un='$aurhelper -Rns'                                             # uninstall package
# alias up='$aurhelper -Syu'                                             # update system/package/aur
# alias pl='$aurhelper -Qs'                                              # list installed package
# alias pa='$aurhelper -Ss'                                              # list available package
# alias pc='$aurhelper -Sc'                                              # remove unused cache
# alias po='$aurhelper -Qtdq | $aurhelper -Rns -'                        # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
# alias vc='code'                                                        # gui code editor
# alias fastfetch='fastfetch --logo-type kitty'
alias ls="eza -a --color=always --long --no-filesize --icons=always --no-time --no-user --no-permissions --no-symlinks"
alias ll="$ls"
alias la="eza -la --color=always --icons=always"
alias tree="eza --tree --color=always --icons=always"
alias cd="z"
alias tb="adb shell pm disable-user --user 0"
alias db="adb shell pm uninstall -k --user 0"
alias ab="adb shell cmd package install-existing --user 0"
alias lg="lazygit"

# # Directory navigation shortcuts
# alias ..='cd ..'
# alias ...='cd ../..'
# alias .3='cd ../../..'
# alias .4='cd ../../../..'
# alias .5='cd ../../../../..'

# # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
# alias mkdir='mkdir -p'

#  This is your file 
# Add your configurations here
# export EDITOR=nvim
unset -f command_not_found_handler # Uncomment to prevent searching for commands not found in package manager

export PATH=$PATH:/home/hyde/.spicetify
