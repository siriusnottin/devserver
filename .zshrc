# detect on which system we are running on (ubuntu or macos)
if [ -f /etc/os-release ]; then
  source /etc/os-release
  OS=$ID # ubuntu
elif [ -f /usr/bin/sw_vers ]; then
  OS="macos"
fi

# Fig pre block. Keep at the top of this file.
[[ $OS == macos && -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

### ZNAP
# Download Znap, if it's not there yet.
[[ -f ~/.zsh-plugins/zsh-snap/znap.zsh ]] ||
  git clone --depth 1 -- \
    https://github.com/marlonrichert/zsh-snap.git ~/.zsh-plugins/zsh-snap

# Start Znap
source ~/.zsh-plugins/zsh-snap/znap.zsh
###

if [[ $OS == "macos" ]]; then
  source ~/.zprofile

  export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

znap source ohmyzsh/ohmyzsh

znap prompt spaceship-prompt/spaceship-prompt

# znap source zsh-users/zsh-completions
znap source zsh-users/zsh-autosuggestions

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
znap source zsh-users/zsh-syntax-highlighting

znap source supercrabtree/k

zstyle ':omz:update' mode disabled # managed by znap

omz_plugins=(
  zsh-interactive-cd
  git
  npm
  wp-cli
)
[[ $OS == "macos" ]] && omz_plugins+=(macos)

for plugin in "${omz_plugins[@]}"; do
  znap source ohmyzsh/ohmyzsh plugins/$plugin
done

# export FZF_BASE=~[ohmyzsh/ohmyzsh]/plugins/fzf
[[ $OS == "macos" ]] && export EDITOR="code -w"

### HOMEBREW
case $OS in
macos)
  znap eval brew-shellenv 'brew shellenv'
  ;;
ubuntu)
  znap function _brew brew 'eval brew "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  compctl -K _brew brew
  ;;
esac
###

# https://github.com/roots/trellis-cli#virtualenv
znap function _trellis trellis 'eval "$(trellis shell-init zsh)"'
compctl -K _trellis trellis

znap function _pyenv pyenv 'eval "$( pyenv init - --no-rehash )"'
compctl -K _pyenv pyenv
znap eval pip-completion 'pip completion --zsh'

# NVM
export NVM_COMPLETION=true
# export NVM_LAZY_LOAD=true
znap source lukechilds/zsh-nvm

if [[ $OS == macos ]]; then

  # use gnu-sed instead of the mac osx sed
  alias sed=gsed

  # Create a folder and move into it in one command
  function mkcd() { mkdir -p "$@" && cd "$_"; }

  # fd - cd to selected directory
  fd() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune \
      -o -type d -print 2>/dev/null | fzf +m) &&
      cd "$dir"
  }

  # fh - search in your command history and execute selected command
  fh() {
    eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
  }

  alias g='git'

  alias sync='./sync.sh'

  # =================== Spotify ===============================
  # Spotify is supported using the OMZSH MacOS plugin. (using the official Spotify API)
  # Raycast is also using the official API.

  alias spp="spotify pause"

  spotify() {
    local track=$(spotify status track)
    local artist=$(spotify status artist)
    case "$1" in
    show)
      printf "%s\n" "$track ($artist)"
      ;;
    search)
      local search="$track $artist music"
      google "$search"
      ;;
    *)
      printf "Usage: spotifyshow [show|search]"
      ;;
    esac
  }

  # GitHub
  alias gho="gh repo view -w"

fi # end macos

# React
cra() {
  if [ -z "${1// /}" ]; then
    echo "No application name provided" >&2
    return 1
  else
    npx create-react-app "$1"
  fi
}

export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
znap eval iterm2 'curl -fsSL https://iterm2.com/shell_integration/zsh'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# ==========================================================
# Fig post block. Keep at the bottom of this file.
[[ $OS == macos && -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && . "$HOME/.fig/shell/zshrc.post.zsh"
