#!/usr/bin/env bash
# Shows what each component of the dotfiles is missing, then installs the picked ones.
#   ./install.sh              show the status and pick (default: every incomplete component)
#   ./install.sh nvim tmux    install these, no prompt (names, numbers or "all")
#   ./install.sh --check      only show the status
#   --pm, --release           take nvim's tools that have an official release binary (nvim,
#                             tree-sitter, go, node/npm, rg, fd, clangd) from the package manager or
#                             from those releases, instead of asking (default: release on apt, pm on
#                             pacman); the rest always comes from the package manager

DOT=~/.dotfiles
USER_PATH=$PATH
# Release binaries and apt's fd land in ~/.local/bin.
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
# Lowest usable versions: nvim-treesitter (main branch) needs nvim 0.12 and tree-sitter 0.26.1.
declare -A MIN=([nvim]=0.12 [tree-sitter]=0.26.1)
# Commands that can come from their official release instead, see install_release.
RELEASES="nvim tree-sitter go node npm rg fd clangd"
# Asset arch names: nvim and rg/fd take ARCH, tree-sitter and node ALT, go GOARCH.
case $(uname -m) in
  x86_64) ARCH=x86_64 ALT=x64 GOARCH=amd64 ;;
  aarch64 | arm64) ARCH=aarch64 ALT=arm64 GOARCH=arm64 RELEASES=${RELEASES% clangd} ;; # clangd: x86_64 only
  *) RELEASES= ;;
esac
# Package providing a command, when its name differs. Empty: not in the repos, see install_cmds.
declare -A PACMAN=([nvim]=neovim [tree-sitter]=tree-sitter-cli [cc]=base-devel [node]=nodejs
  [rg]=ripgrep [xxd]=tinyxxd [identify]=imagemagick [clangd]=clang)
declare -A APT=([nvim]=neovim [tree-sitter]=tree-sitter-cli [wezterm]= [cc]=build-essential
  [node]=nodejs [go]=golang-go [rg]=ripgrep [fd]=fd-find [identify]=imagemagick)
if command -v pacman >/dev/null; then PM=pacman
elif command -v apt-get >/dev/null; then PM=apt
fi

function missing_cmds() {
  local c
  for c in ${CMDS[$1]}; do command -v "$c" >/dev/null && ! too_old "$c" || echo "$c"; done
}

# Whether command $1 is older than its MIN version.
function too_old() {
  local v
  [ -n "${MIN[$1]}" ] || return 1
  v=$("$1" --version 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
  [ "$(printf '%s\n' "${MIN[$1]}" "$v" | sort -V | head -1)" != "${MIN[$1]}" ]
}

# What component $1 still lacks: commands, links and setup steps.
function missing() {
  local c l
  for c in $(missing_cmds "$1"); do echo "$c${MIN[$c]:+>=${MIN[$c]}}"; done
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
  local c pkgs=()
  [ -n "$PM" ] || { echo "No pacman or apt-get: install these by hand: $*" >&2; return 1; }
  for c; do
    if [ $PM = pacman ]; then pkgs+=(${PACMAN[$c]-$c}); else pkgs+=(${APT[$c]-$c}); fi
  done
  if [ ${#pkgs[@]} -gt 0 ]; then
    echo "Installing ${pkgs[*]}"
    if [ $PM = pacman ]; then sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    else sudo apt-get update && sudo apt-get install -y "${pkgs[@]}"
    fi || return 1
  fi
  [ $PM = apt ] || return 0
  for c; do
    case $c in
      fd) [ -e ~/.local/bin/fd ] || ln -s /usr/bin/fdfind ~/.local/bin/fd ;;
      wezterm) echo "wezterm is not in apt: install it from https://wezterm.org/install/linux.html" >&2 ;;
    esac
  done
}

# Latest release tag of GitHub repo $1, read from where /releases/latest redirects.
function gh_latest() {
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's|.*/||'
}

# Moves the unpacked release dir $1 to ~/.local/opt/$2 and links its binaries $3... into ~/.local/bin.
function place() {
  local dir=$1 name=$2 b
  shift 2
  rm -rf ~/.local/opt/"$name" && mkdir -p ~/.local/opt && mv "$dir" ~/.local/opt/"$name" || return 1
  for b; do ln -sfn ~/.local/opt/"$name/$b" ~/.local/bin/"${b##*/}"; done
}

# Installs command $1 from its latest official release.
function install_release() {
  local t v d ok
  t=$(mktemp -d)
  echo "Installing $1 from its release"
  case $1 in
    nvim)
      d=nvim-linux-${ARCH/aarch64/arm64}
      curl -fsSL https://github.com/neovim/neovim/releases/download/stable/$d.tar.gz | tar -xz -C "$t" \
        && place "$t/$d" nvim bin/nvim ;;
    tree-sitter)
      curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$ALT.gz \
        | gunzip > "$t/tree-sitter" && install -m 755 "$t/tree-sitter" ~/.local/bin/ ;;
    go)
      v=$(curl -fsSL 'https://go.dev/VERSION?m=text') && v=${v%%$'\n'*} \
        && curl -fsSL https://go.dev/dl/$v.linux-$GOARCH.tar.gz | tar -xz -C "$t" \
        && place "$t/go" go bin/go bin/gofmt ;;
    node | npm) # LTS; npm comes with it
      v=$(curl -fsSL https://nodejs.org/dist/index.json) \
        && v=$(grep -o '"version":"v[0-9.]*"[^}]*"lts":"' <<<"$v" | head -1 | cut -d'"' -f4) \
        && d=node-$v-linux-$ALT && curl -fsSL https://nodejs.org/dist/$v/$d.tar.gz | tar -xz -C "$t" \
        && place "$t/$d" node bin/node bin/npm bin/npx ;;
    rg)
      [ $ARCH = x86_64 ] && d=x86_64-unknown-linux-musl || d=aarch64-unknown-linux-gnu
      v=$(gh_latest BurntSushi/ripgrep) && d=ripgrep-$v-$d \
        && curl -fsSL https://github.com/BurntSushi/ripgrep/releases/download/$v/$d.tar.gz | tar -xz -C "$t" \
        && place "$t/$d" ripgrep rg ;;
    fd)
      v=$(gh_latest sharkdp/fd) && d=fd-$v-$ARCH-unknown-linux-musl \
        && curl -fsSL https://github.com/sharkdp/fd/releases/download/$v/$d.tar.gz | tar -xz -C "$t" \
        && place "$t/$d" fd fd ;;
    clangd)
      v=$(gh_latest clangd/clangd) \
        && curl -fsSL -o "$t/clangd.zip" https://github.com/clangd/clangd/releases/download/$v/clangd-linux-$v.zip \
        && unzip -q "$t/clangd.zip" -d "$t" && place "$t/clangd_$v" clangd bin/clangd ;;
  esac
  ok=$?
  rm -rf "$t"
  return $ok
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
    # The session dir is needed for mini.nvim session save. lazy.nvim installs missing plugins on
    # launch but leaves existing checkouts alone, so an older checkout (nvim-treesitter on master)
    # breaks the config: restore puts every plugin on its lazy-lock.json commit.
    nvim)
      mkdir -p ~/.local/share/nvim/session
      if command -v nvim >/dev/null && ! too_old nvim; then
        echo "Restoring nvim plugins to lazy-lock.json"
        nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || echo "Lazy restore failed: run :Lazy restore in nvim" >&2
      fi ;;
  esac
}

while [[ $1 == -* ]]; do
  case $1 in
    -h | --help) sed -n '2,/^$/p' "$0" | cut -c3-; exit ;;
    -c | --check) show_status; exit ;;
    --pm | --release) from=${1#--} ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

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
releases=$(grep -xF -f <(printf '%s\n' $RELEASES) <<<"$cmds" | sed 's/^npm$/node/' | sort -u)
if [ -n "$releases" ] && [ -z "$from" ]; then
  # apt's nvim and tree-sitter are older than MIN
  [ "$PM" = pacman ] && default=pm || default=release
  read -rp "Install $(xargs <<<"$releases") from the package manager or their official releases? (pm or release) [$default]: " from
  from=${from:-$default}
fi
case $from in pm | release | "") ;; *) echo "Unknown source: $from (pm or release)" >&2; exit 1 ;; esac
# The package manager goes first: it brings curl, tar, gzip and unzip for the releases.
[ "$from" = release ] && cmds=$(grep -vxF -f <(printf '%s\n' $RELEASES) <<<"$cmds")
[ -z "$cmds" ] || install_cmds $cmds || exit 1
if [ "$from" = release ]; then
  for c in $releases; do install_release "$c" || exit 1; done
fi
for c in "${selected[@]}"; do echo "Setting up $c"; setup "$c"; done
show_status
[[ :$USER_PATH: == *:$HOME/.local/bin:* ]] || echo "Add ~/.local/bin to your PATH, then open a new shell"
for c in $RELEASES; do
  if PATH=$USER_PATH command -v "$c" >/dev/null && PATH=$USER_PATH too_old "$c"; then
    echo "$c in your PATH ($(PATH=$USER_PATH command -v "$c")) is older than ${MIN[$c]}: put ~/.local/bin first"
  fi
done
