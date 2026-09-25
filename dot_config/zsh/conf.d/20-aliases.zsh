alias vi="vim"
alias vim="vim"
alias view="vim -R"
alias code-p='code "/Users/shimopino/Library/Application Support/Code/User/prompts"'
alias code-p-insiders='code-insiders "/Users/shimopino/Library/Application Support/Code - Insiders/User/prompts"'

# eza
alias ls='eza'
alias ll='eza -l --git'
alias la='eza -la --git'
alias lt='eza --tree'

# エイリアスを張るのが定番(~/.zshrc に)
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

alias zed='mise exec -- zed'

glow90() {
    glow -w $(( COLUMNS * 9 / 10 )) "$@"
}
