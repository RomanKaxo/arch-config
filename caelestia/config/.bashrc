#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# >>> Codex installer >>>
export PATH="/home/roman/.local/bin:$PATH"
# <<< Codex installer <<<

# Caelestia terminal colours.
if [[ -t 1 && -r "$HOME/.local/state/caelestia/sequences.txt" ]]; then
    cat "$HOME/.local/state/caelestia/sequences.txt"
fi
