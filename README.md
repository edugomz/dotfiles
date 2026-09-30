# My dotfiles

## dependencies

- tmux
- i3
- dependencies of https://github.com/vivien/i3blocks-contrib
- rofi
- feh
- nvim
  - rg
  - fd
- vimv
- flameshot
- xkblayout


## Project workflow (tmux, one session per project dir)

Each project dir gets its own tmux session, so its nvim and claude windows stay grouped.

```
tmux server
├── dotfiles          <- session = project dir
│   ├── 0: nvim       <- code + fugitive in nvim tabs
│   ├── 1: claude     <- agent session 01
│   └── 2: claude     <- agent session 02 (prefix+a)
└── myrepo
    ├── 0: nvim
    └── 1: claude
```

`bin/tp` does the setup; `install.sh` links it to `~/.local/bin/tp`.

### Steps

1. Open a project: `tp ~/code/myrepo` (or `tp` inside the dir).
   It creates session `myrepo` with window `nvim` and window `claude`, then attaches.
   Running `tp` again for the same dir just switches to the existing session.
2. Work with the agent in the `claude` window (`prefix+1`).
3. Check git and diffs in the `nvim` window (`prefix+0`), using fugitive (`:Git`) and nvim tabs.
4. Need another agent in the same dir: `prefix+a` opens a new `claude` window there.
5. Open another repo from inside tmux: `prefix+T` opens a fuzzy list of the dirs in `~/.tmux-session-paths`.
   Pick one and it runs `tp` on it, creating the session or switching to it if it already exists.
   `tp ~/code/other` from any existing shell works too.

`~/.tmux-session-paths` holds one project dir per line; `~` is expanded, and blank lines and `#` comments are skipped:

```
# work
~/code/worksys/myrepo
~/code/personal/other
```
6. Switch between projects:
   - `prefix+w` shows the tree of all sessions and windows; pick one with `Enter`.
   - `prefix+f` opens a fuzzy picker of sessions; type part of the name and press `Enter`.
   - `prefix+L` jumps back to the last session, handy for toggling between two projects.
   - `prefix+n` / `prefix+p` still cycle windows inside the current session.
7. Close a project and all its windows: `prefix+w`, highlight the session, `x`, `y`.
   Closing the current one switches to another project instead of detaching.
   Save nvim buffers first; claude chats can be picked up again with `claude --resume`.
8. Leave everything running with `prefix+d`; later, `tp <dir>` or `tmux attach` brings it back.

Quitting nvim or claude leaves a shell in its window, so the window layout survives.

### Know which agent is waiting on you

In claude, run `/config` and set notifications to the terminal bell.
tmux then marks the window with `!` in the status bar and in the `prefix+w` tree when that agent needs input.

TODO

- .gdbinit
