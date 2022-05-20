source ~/.zsh-plugins/zsh-snap/znap.zsh

ZSH_THEME="robbyrussell"

znap source ohmyzsh/ohmyzsh

znap prompt ohmyzsh/ohmyzsh robbyrussell

plugins=(npm wp-cli git zsh-interactive-cd)

znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
znap source supercrabtree/k

# https://github.com/roots/trellis-cli#virtualenv
znap function _trellis trellis              'eval "$(trellis shell-init zsh)"'
compctl -K    _trellis trellis

# NVM
export NVM_COMPLETION=true
# export NVM_LAZY_LOAD=true
znap source lukechilds/zsh-nvm

# Create files faster
# Touch Code
tcode() {
  if [ "$1" = "-r" ]; then
    mkdir -p "$(dirname "$2")"
    touch "$2"
    code -r "$2"
  elif [ "$2" = "-r" ]; then
    mkdir -p "$(dirname "$1")"
    touch "$1"
    code -r "$1"
  else
    mkdir -p "$(dirname "$1")"
    touch "$1"
    code "$1"
  fi
}

alias zshconfig="code -r ~/.zshrc"
alias ohmyzsh="code -r ~/.oh-my-zsh"

# GitHub
alias gho="gh repo view -w"

# React
cra() {
  if [ -z "$1" ]; then
    echo "No application name provided"
    return 1
  else
    npx create-react-app $1
  fi
} 
