#!/bin/sh

function link_dotfile_dir() {
  ln -s ~/.dotfiles/.config/$1 ~/.config/$1
}

function link_dirs() {
  echo "Linking files"
  ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
  ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf

  echo "Linking dirs"
  # link_dotfile_dir "alacritty"
  link_dotfile_dir "nvim"
  link_dotfile_dir "wezterm"
  # link_dotfile_dir "i3"
  # link_dotfile_dir "i3status"
  # link_dotfile_dir "i3status-contrib"
  # init submodule ...

  # needed for mini.nvim session save
  mkdir -p ~/.local/share/nvim/session
  # lazy.nvim bootstraps itself on first nvim launch — no manual step needed
}

function create_dotfiles_dir() {
  path=$(pwd)
  cd ~
  if [[ -e .dotfiles ]]; then
    echo "~./dotfiles already exists, run -F to override"
    return
  fi
  mv $path .dotfiles
  link_dirs
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -F | --force )
    # TODO use force
    force=1
    echo "$force"
    exit
    ;;
  -H | --help )
    shift; 
    echo "-F to override current .dotfiles"
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# create_dotfiles_dir
link_dirs

