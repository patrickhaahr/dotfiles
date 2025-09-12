# Path to your Oh My Zsh installation.
export ZSH="/usr/share/oh-my-zsh"xport ZSH="/usr/share/oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# plugins
plugins=(
  archlinux
  command-not-found
  sudo
)

# Source Oh My Zsh framework itself
# This MUST come before sourcing other plugins that might depend on it.
source "$ZSH/oh-my-zsh.sh"

# --- Sourcing System-Wide Plugins (from pacman/AUR packages) ---
# These are now sourced directly instead of being in the plugins array.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.plugin.zsh

# --- Plugin-Specific Styling ---
# This must come AFTER the plugins have been sourced.
# Completion styling
zstyle ':completion:*' menu no

# fzf-tab specific styling 
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
fi

# --- Aliases ---
# Basic lsd aliases
alias ls='lsd --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias ll='lsd -l --group-dirs=first'
alias lla='lsd -la --group-dirs=first'
alias lal='lsd -la --group-dirs=first'

# Tree view aliases
alias lt='lsd --tree --depth=2'
alias lta='lsd --tree --depth=2 -a'
alias ltl='lsd --tree --depth=2 -l'

alias cursor="~/.local/bin/Cursor.AppImage"
alias vim="/usr/bin/nvim" 

# --- Keybindings ---
bindkey "^f" autosuggest-accept  
bindkey "^p" history-search-backward
bindkey "^n" history-search-forward

# --- PATH Modifications ---
# Add local binaries (e.g., from pipx) to PATH
export PATH="$HOME/.local/bin:$PATH"
# Add Go binaries to PATH (for tools installed via 'go install')
export PATH="$PATH:$HOME/go/bin"

# --- History Settings ---
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# --- Tmux Auto-Attach ---
# Auto-attach to or create a tmux session when opening a new terminal
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach -t main || tmux new -s main
fi
export ASPNETCORE_ENVIRONMENT=Development
export EDITOR=nvim
export VISUAL=nvim

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/patrickhaahr/.lmstudio/bin"
# End of LM Studio CLI section

