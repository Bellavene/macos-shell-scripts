export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1

setopt hist_expire_dups_first # expire duplicate entries first when trimming history
setopt hist_find_no_dups      # do not display a line previously found
setopt hist_ignore_all_dups   # ignore all double commands in history
setopt hist_ignore_dups       # don't record an entry that was just recorded again
setopt hist_ignore_space      # don't add commands to history that start with space
setopt hist_reduce_blanks     # reduce blanks in history
setopt hist_save_no_dups      # don't write duplicate entries in the history file
setopt inc_append_history     # write to the history file immediately, not when the shell exits
setopt share_history          # share history between all sessions

# Minimal command prompt / only path
export PS1=%B%F{green}%~/%f%b

# Those list pressed Keycodes
alias keycodes="xxd -psd"
alias keycodes2="sed -n l"
alias keycodes3="infocmp -cL"

# Global abbriviations / links
alias -g docs=~/Documents
alias -g shots=~/Pictures/Screenshots
alias -g projects=~/Projects
alias -g sd=/Volumes/Untitled

# Kills Adobe Creative Cloud processes
alias adobe="pkill -9 -fi \'core sync\'; pkill -9 -fi \'creative cloud\'; pkill -9 -fi \'adobe desktop service\'; pkill -9 -fi \'adobeipcbroker\'; pkill -9 -fi \'logtransport\'"

# File exstensions handling
alias -s lua="editor"
alias -s txt="editor"
alias -s conf="editor"
alias -s cfg="editor"
alias -s ini="editor"
alias -s jpg="ascii-image-converter -C"
alias -s jpeg="ascii-image-converter -C"
alias -s png="ascii-image-converter -C"
alias -s tiff="ascii-image-converter -C"

# insert last command result
zmodload -i zsh/parameter
insert-last-command-output() {
  LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output
# Ctrl+V Insert last output
bindkey -r '\Cv'
bindkey '\Cv' insert-last-command-output


# FZF List and kill processes. Option + K
fzf-kill() {
ps -aevrc | fzf --layout=reverse-list --bind "alt-w:reload(ps -aevr)" | xargs kill -9 &> /dev/null
}
zle -N fzf-kill
bindkey '\ek' fzf-kill


# Uninstall macos applications through FZF and app-cleaner.sh
bindkey -s "\eu" "uninstall\n"


# Escape = reset prompt line
# Double Escape = quit
double_escape() {
zle kill-whole-line
exit
}
zle -N double_escape
bindkey '\E' kill-whole-line
bindkey '\E\E' double_escape

# Option + Q exit
bindkey '\eq' double_escape


# List open ports
listening() {
    if [ $# -eq 0 ]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    elif [ $# -eq 1 ]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
    else
        echo "Usage: listening [pattern]"
    fi
}


# Opens (Chromium based) browser's history in FZF. Option + C / copies link through pbcopy.
vivaldi-history() {
  local cols sep
  cols=$(( COLUMNS / 3 ))
  sep='{::}'
  #  Change word "Vivaldi" to "Chromium" or "Brave" or etc.
  cp -f ~/Library/Application\ Support/Vivaldi/Default/History /tmp/h

  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi --bind 'alt-c:execute-silent(echo {} | sed "s/.* //" | pbcopy)' | sed 's#.*\(https*://\)#\1#' | xargs open
}
# binds browser history to Option + G
zle     -N   vivaldi-history
bindkey '\eg' vivaldi-history


# Open path in new iTerm shell window. Also works as "open", but opens passed terminal command in new window.
function window() {
  # Must not have trailing semicolon, for iTerm compatibility
  local command="cd \\\"$PWD\\\"; clear"
  (( $# > 0 )) && command="${command}; $*"

    osascript \
        -e 'tell application "iTerm2" to tell current window to set newWindow to (create window with default profile)'\
        -e "tell application \"iTerm2\" to tell current session of newWindow to write text \"${command} ;exit\"" \
        -e "delay 1" \
        -e "tell application \"iTerm2\" to activate" \
}


# Alt+Shift+S to prepend "sudo " to line
function _insert_sudo {
prefix="sudo"
BUFFER="$prefix $BUFFER"
CURSOR=$(($CURSOR + $#prefix + 1))
}
zle -N insert-sudo _insert_sudo
bindkey "\eS" insert-sudo


# Alt+E Edit command line
zle -N 'edit-command-line'
bindkey '\ee' edit-command-line


# Prompt Selection / Shift + direction / Shift + Option + direction
shift-arrow() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle $1
}
shift-left()  shift-arrow backward-char
shift-right() shift-arrow forward-char
shift-up()    shift-arrow beginning-of-line
shift-down()  shift-arrow end-of-line
shift-alt-left()  shift-arrow backward-word
shift-alt-right() shift-arrow forward-word
zle -N shift-left
zle -N shift-right
zle -N shift-up
zle -N shift-down
zle -N shift-alt-left
zle -N shift-alt-right
bindkey "^[[1;2A" shift-up
bindkey "^[[1;2B" shift-down
bindkey "^[[1;2D" shift-left
bindkey "^[[1;2C" shift-right
bindkey "^[[1;10D" shift-alt-left
bindkey "^[[1;10C" shift-alt-right


# Backspace deletes also selected text
delete-selection() {
  if ((REGION_ACTIVE)) then
     zle kill-region
  else
     zle backward-delete-char
  fi
}
zle -N delete-selection
bindkey -e "^?" delete-selection


# Insert last executed command output
zmodload -i zsh/parameter
insert-last-command-output() {
  LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output
# Ctrl+V to Insert last output
bindkey -r '\Cv'
bindkey '\Cv' insert-last-command-output


# Option + A selects all typed text
select-all() {
    local buflen=$(echo -n "$BUFFER" | wc -m | bc)
    CURSOR=$buflen   # if this is messing up try: CURSOR=9999999
    zle set-mark-command
    while [[ $CURSOR > 0 ]]; do
        zle beginning-of-line
    done
}
zle -N select-all
bindkey -e "\ea" select-all


# Copy / Cut / Paste shell selection using pbcopy/pbpaste. Option + C / V / X
pb-copy-region () {
  zle copy-region-as-kill
  print -rn $CUTBUFFER | pbcopy
  ((REGION_ACTIVE = 0))
}
pb-cut-region () {
  zle copy-region-as-kill
  print -rn $CUTBUFFER | pbcopy
  zle kill-region
}
pb-yank () {
  CUTBUFFER=$(pbpaste)
  zle yank
}
zle -N pb-copy-region
bindkey -e '\ec' pb-copy-region
zle -N pb-cut-region
bindkey -e '\ex' pb-cut-region
zle -N pb-yank
bindkey '\ev' pb-yank


# Option + z Undo
bindkey '\ez' undo


# Outputs internal and external IP addresses
ipp() {
  printf "Public IP: " >&2
  curl ipinfo.io/ip
}
ipl() {
  printf "Local IP: " >&2
  ifconfig | grep "inet " | grep -v 127.0.0.1 | head -n1 | cut -d' ' -f2
}
alias ip="ipl; ipp"
