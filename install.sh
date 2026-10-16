#!/usr/bin/env bash
# Shows what each component of the dotfiles is missing, then installs the picked ones.
#   ./install.sh              show the status and pick (default: every incomplete component)
#   ./install.sh nvim tmux    install these, no prompt (names, numbers or "all")
#   ./install.sh --check      only show the status

DOT=~/.dotfiles
USER_PATH=$PATH
# On apt, nvim, tree-sitter and fd land in ~/.local/bin.
PATH=~/.local/bin:$PATH
COMPONENTS=(git tmux nvim wezterm)

# Commands each component needs.
# tmux: fzf (tmux-sessions pick), jq (tmux-claude-resurrect), git (TPM).
# nvim: tree-sitter + cc (nvim-treesitter), node/npm (pyright), go (mason builds gopls),
# curl/unzip/tar/gzip (mason, vim-doge), rg/fd (telescope), xxd (hex.nvim), clangd,
# identify (image.nvim runs magick, or convert + identify on ImageMagick 6).
declare -A CMDS=(
  [git]="git"
  [tmux]="tmux git fzf jq"
  [nvim]="nvim git tree-sitter cc node npm go curl unzip tar gzip rg fd xxd identify clangd"
  [wezterm]="wezterm"
)
# Links each component needs, as <path in ~/.dotfiles>:<path in ~>.
declare -A LINKS=(
  [git]=".gitconfig:.gitconfig"
  [tmux]=".tmux.conf:.tmux.conf bin/tp:.local/bin/tp"
  [nvim]=".config/nvim:.config/nvim"
  [wezterm]=".config/wezterm:.config/wezterm"
)
# Package providing a command, when its name differs. Empty: not in the repos, see install_cmds.
declare -A PACMAN=([nvim]=neovim [tree-sitter]=tree-sitter-cli [cc]=base-devel [node]=nodejs
  [rg]=ripgrep [xxd]=tinyxxd [identify]=imagemagick [clangd]=clang)
declare -A APT=([nvim]= [tree-sitter]= [wezterm]= [cc]=build-essential [node]=nodejs
  [go]=golang-go [rg]=ripgrep [fd]=fd-find [identify]=imagemagick)

function missing_cmds() {
  local c
  for c in ${CMDS[$1]}; do
    command -v "$c" >/dev/null && ! { [ "$c" = nvim ] && nvim_too_old; } || echo "$c"
  done
}

# nvim-treesitter (main branch) needs nvim 0.12.
function nvim_too_old() {
  local v
  v=$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\).*/\1/p')
  [ "$(printf '%s\n' 0.12 "$v" | sort -V | head -1)" != 0.12 ]
}

# What component $1 still lacks: commands, links and setup steps.
function missing() {
  local l
  missing_cmds "$1" | sed 's/^nvim$/nvim>=0.12/'
  for l in ${LINKS[$1]}; do [ -e ~/"${l#*:}" ] || [ -L ~/"${l#*:}" ] || echo "~/${l#*:}"; done
  case $1 in
    tmux) [ -d ~/.tmux/plugins/tpm ] || echo "tpm" ;;
    nvim) [ -d ~/.local/share/nvim/session ] || echo "~/.local/share/nvim/session" ;;
  esac
}

# Link targets of component $1 already taken by another file; installing leaves them alone.
function taken() {
  local l dst
  for l in ${LINKS[$1]}; do
    dst=~/${l#*:}
    { [ -e "$dst" ] || [ -L "$dst" ]; } && [ "$(readlink -f "$dst")" != "$(readlink -f "$DOT/${l%%:*}")" ] \
      && echo "~/${l#*:}"
  done
}

function show_status() {
  local i c m t
  for i in "${!COMPONENTS[@]}"; do
    c=${COMPONENTS[$i]}
    m=$(missing "$c" | xargs) t=$(taken "$c" | xargs)
    printf '%d) %-8s %s\n' $((i + 1)) "$c" \
      "$([ -z "$m$t" ] && echo ok)${m:+missing: $m}${m:+${t:+, }}${t:+not linked, file exists: $t}"
  done
}

# Maps names, 1-based numbers, "all" and "none" to component names.
function resolve() {
  local w
  for w; do
    case $w in
      all) printf '%s\n' "${COMPONENTS[@]}" ;;
      none) ;;
      *)
        if [[ $w =~ ^[0-9]+$ ]] && ((w >= 1 && w <= ${#COMPONENTS[@]})); then echo "${COMPONENTS[w - 1]}"
        elif [ -n "${CMDS[$w]+x}" ]; then echo "$w"
        else echo "Unknown component: $w (pick from: ${COMPONENTS[*]})" >&2; return 1
        fi ;;
    esac
  done
}

# Installs the commands $@ with the system package manager.
function install_cmds() {
  local pm c pkgs=()
  if command -v pacman >/dev/null; then pm=pacman
  elif command -v apt-get >/dev/null; then pm=apt
  else echo "No pacman or apt-get: install these by hand: $*" >&2; return 1
  fi
  for c; do
    if [ $pm = pacman ]; then pkgs+=(${PACMAN[$c]-$c}); else pkgs+=(${APT[$c]-$c}); fi
  done
  if [ ${#pkgs[@]} -gt 0 ]; then
    echo "Installing ${pkgs[*]}"
    if [ $pm = pacman ]; then sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    else sudo apt-get update && sudo apt-get install -y "${pkgs[@]}"
    fi || return 1
  fi
  [ $pm = apt ] || return 0
  for c; do
    case $c in
      fd) [ -e ~/.local/bin/fd ] || ln -s /usr/bin/fdfind ~/.local/bin/fd ;;
      # apt's neovim is too old for this config, and it has no tree-sitter CLI: take the latest
      nvim)
        rm -rf ~/.local/opt/nvim-linux-x86_64 && mkdir -p ~/.local/opt
        curl -fsSL https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz \
          | tar -xz -C ~/.local/opt
        ln -sfn ~/.local/opt/nvim-linux-x86_64/bin/nvim ~/.local/bin/nvim ;;
      tree-sitter)
        curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
          | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter ;;
      wezterm) echo "wezterm is not in apt: install it from https://wezterm.org/install/linux.html" >&2 ;;
    esac
  done
}

# Links the config of component $1 and runs its setup steps.
function setup() {
  local l dst
  for l in ${LINKS[$1]}; do
    dst=~/${l#*:}
    mkdir -p "$(dirname "$dst")"
    # Skip an existing target: `ln -s` onto a dir symlink would link inside it.
    [ -e "$dst" ] || [ -L "$dst" ] || ln -s "$DOT/${l%%:*}" "$dst"
  done
  case $1 in
    # tmux plugins (resurrect + continuum) via TPM
    tmux)
      [ -d ~/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
      ~/.tmux/plugins/tpm/bin/install_plugins ;;
    # needed for mini.nvim session save; lazy.nvim bootstraps itself on first nvim launch
    nvim) mkdir -p ~/.local/share/nvim/session ;;
  esac
}

case $1 in
  -h | --help) sed -n '2,5p' "$0" | cut -c3-; exit ;;
  -c | --check) show_status; exit ;;
esac

if [ $# -eq 0 ]; then
  show_status
  for c in "${COMPONENTS[@]}"; do [ -z "$(missing "$c")" ] || defaults+=("$c"); done
  read -rp "Install which? (names, numbers, all or none) [${defaults[*]:-none}]: " answer
  set -- ${answer:-${defaults[*]:-none}}
fi
names=$(resolve "$@") || exit 1
for c in "${COMPONENTS[@]}"; do grep -qx "$c" <<<"$names" && selected+=("$c"); done
[ ${#selected[@]} -gt 0 ] || { echo "Nothing to install"; exit; }

mkdir -p ~/.local/bin ~/.config
cmds=$(for c in "${selected[@]}"; do missing_cmds "$c"; done | sort -u)
[ -z "$cmds" ] || install_cmds $cmds || exit 1
for c in "${selected[@]}"; do echo "Setting up $c"; setup "$c"; done
show_status
[[ :$USER_PATH: == *:$HOME/.local/bin:* ]] || echo "Add ~/.local/bin to your PATH, then open a new shell"
PATH=$USER_PATH command -v nvim >/dev/null && PATH=$USER_PATH nvim_too_old \
  && echo "nvim in your PATH ($(PATH=$USER_PATH command -v nvim)) is older than 0.12: put ~/.local/bin first"
