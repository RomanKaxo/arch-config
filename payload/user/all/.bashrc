#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# >>> Codex installer >>>
export PATH="@HOME@/.local/bin:$PATH"
# <<< Codex installer <<<

# Coherent desktop prompt; evaluated only in interactive shells.
__desktop_prompt() {
    [[ -r "$HOME/.config/desktop/current/prompt.bash" ]] && source "$HOME/.config/desktop/current/prompt.bash"
}
PROMPT_COMMAND+=(__desktop_prompt)
if [[ -t 1 && -n ${KITTY_WINDOW_ID:-} && -z ${DESKTOP_FASTFETCH_SHOWN:-} ]] && command -v fastfetch >/dev/null; then
    DESKTOP_FASTFETCH_SHOWN=1
    fastfetch
fi
