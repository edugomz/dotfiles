# My dotfiles

## dependencies

- tmux
- i3
- dependencies of https://github.com/vivien/i3blocks-contrib
- rofi
- feh
- nvim, with the tools in `.config/nvim/README.md` "Requirements"
- vimv
- flameshot
- xkblayout

`./install.sh` shows what each component (git, tmux, nvim, wezterm) is missing and installs the ones you pick.
It defaults to every incomplete component; `./install.sh nvim tmux` skips the prompt, and `./install.sh --check` only shows the status.
It asks whether the nvim tools with an official release binary (nvim, tree-sitter, go, node/npm, rg, fd, clangd) come from the package manager or those releases, installed under `~/.local/opt` (`--pm` or `--release` skips that).
The default is releases on apt, whose nvim and tree-sitter are too old, and the package manager on pacman; the other tools always come from the package manager.


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
   If the project was closed but has a saved state, `tp` resumes it with its saved windows instead.
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
7. Close the current project and all its windows: `prefix+X`, `y`.
   It saves the project first, so `prefix+S` can resume it later, then switches to another project instead of detaching.
   For another project: `prefix+w`, highlight the session, `x`, `y` (this keeps its state from the last save).
   Save nvim buffers first.
8. Leave everything running with `prefix+d`; later, `tp <dir>` or `tmux attach` brings it back.
9. Resume closed projects: `prefix+S` (see below).

Quitting nvim or claude leaves a shell in its window, so the window layout survives.

### Know which agent is waiting on you

In claude, run `/config` and set notifications to the terminal bell.
tmux then marks the window with `!` in the status bar and in the `prefix+w` tree when that agent needs input.

### Save and resume projects

[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) saves every session, window, split layout, cwd and nvim.
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) saves every 15 minutes, and every detach (`prefix+d` or closing the terminal) and `prefix+X` saves too.
`bin/tmux-sessions` splits each save into one file per session, so a project you have closed keeps its last state until you resume or forget it.
`bin/tmux-claude-resurrect` hooks in too, so each claude pane comes back with `claude --resume <its own session id>`, even with several claudes in one dir.

Starting tmux restores nothing; you pick what to bring back:

```
resume>
  3/3
  enter: resume  tab: mark  ctrl-x: forget
▌ s3  oct 10 14:19  s3-w1  s3-w2  s3-w3
  s2  oct 10 14:19  s2-w1  s2-w2
  s1  oct 10 14:19  s1-w1  s1-w2
```

- `prefix+S` lists the saved projects that are not open, newest first, with their windows.
  `Enter` resumes the highlighted one, `Tab` marks several to resume together, and `ctrl-x` forgets the highlighted one.
- After a reboot, start plain `tmux` and press `prefix+S`; the empty session `0` goes away once a project is resumed.
  `tp <dir>` and `prefix+T` resume a saved project too.
- Unnamed sessions (`0`, `1`, ...) are not kept; rename one with `prefix+$` to keep it.
- Save now: `prefix+Ctrl-s`.
- Restore everything from the last full save: `prefix+Ctrl-r`.
- Full snapshots live in `~/.local/share/tmux/resurrect/` (`last` points to the newest), per-project ones in `~/.local/share/tmux/sessions/`.
  The extra `claude` lines in each snapshot hold the pane to session id mapping.

TODO

- .gdbinit
