-- Edit text files on another host from this nvim, read and written over ssh (no LSP on them;
-- bin/rnvim is the full remote session). Pick one of M.paths, then a file under it; the file opens
-- as ssh://<host>/<path>, <path> relative to the host's home.
-- A save refuses when the file changed on the host since it was read (an agent there edited it):
-- :e! reloads it, :w! overwrites.
local M = {}

M.paths = {
  pc1 = { 'code/worksys', 'code/worksys/repo' },}

-- One shared connection per host, so each open or save costs a few ms instead of a handshake.
-- BatchMode: a host needing a password fails with an error instead of hanging nvim.
local ssh = { 'ssh', '-o', 'BatchMode=yes', '-o', 'ControlMaster=auto',
  '-o', 'ControlPath=~/.ssh/cm-%C', '-o', 'ControlPersist=10m' }

local function run(host, script, args, stdin)
  local cmd = vim.list_extend(vim.list_extend({}, ssh), { host, 'sh', '-c', vim.fn.shellescape(script), '-' })
  for _, a in ipairs(args) do table.insert(cmd, vim.fn.shellescape(a)) end
  return vim.system(cmd, { stdin = stdin }):wait()
end

local function parse(name)
  return name:match('^ssh://([^/]+)/(.+)$')
end

-- First line: the file's sha256, empty when it does not exist yet; then its bytes.
local READ = [[[ -e "$1" ] || { echo; exit; }; sha256sum < "$1" | cut -c1-64 && cat "$1"]]

-- Write through a temp file so a dropped connection never leaves the file truncated; the mode is
-- copied and a symlink's target replaced. Exit 3 when the sha no longer matches the one read.
local WRITE = [[
f=$(readlink -f "$1"); want=$2; force=$3
have=$([ -e "$f" ] && sha256sum < "$f" | cut -c1-64)
[ "$force" = 1 ] || [ "$have" = "$want" ] || exit 3
cat > "$f.ssh-files.tmp" && { chmod --reference="$f" "$f.ssh-files.tmp" 2>/dev/null; true; } \
  && mv "$f.ssh-files.tmp" "$f" && sha256sum < "$f" | cut -c1-64]]

local function read(ev)
  local host, path = parse(ev.match)
  local r = run(host, READ, { path })
  if r.code ~= 0 then
    return vim.notify(('ssh_files: reading %s failed: %s'):format(ev.match, r.stderr), vim.log.levels.ERROR)
  end
  local sha, body = r.stdout:match('^(%x*)\n(.*)$')
  vim.b[ev.buf].ssh_sha = sha
  local eol = body:sub(-1) == '\n'
  local lines = vim.split(eol and body:sub(1, -2) or body, '\n', { plain = true })
  -- ponytail: LF only; a CRLF file shows ^M, add fileformat detection if one ever needs editing.
  local ul = vim.bo[ev.buf].undolevels
  vim.bo[ev.buf].undolevels = -1 -- a (re)load is not an undo step
  vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
  vim.bo[ev.buf].undolevels = ul
  vim.bo[ev.buf].eol = eol or sha == ''
  vim.bo[ev.buf].modified = false
  vim.api.nvim_buf_call(ev.buf, function() vim.cmd('filetype detect') end)
end

local function write(ev)
  local host, path = parse(ev.match)
  local body = table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), '\n')
  if vim.bo[ev.buf].eol or vim.bo[ev.buf].fixeol then body = body .. '\n' end
  local force = vim.v.cmdbang == 1 and '1' or '0'
  local r = run(host, WRITE, { path, vim.b[ev.buf].ssh_sha or '', force }, body)
  if r.code == 3 then
    return vim.notify(('ssh_files: %s changed on %s since it was read; :e! reloads it, :w! overwrites')
      :format(path, host), vim.log.levels.ERROR)
  elseif r.code ~= 0 then
    return vim.notify(('ssh_files: writing %s failed: %s'):format(ev.match, r.stderr), vim.log.levels.ERROR)
  end
  vim.b[ev.buf].ssh_sha = vim.trim(r.stdout)
  vim.bo[ev.buf].modified = false
  vim.notify(('"%s" written'):format(ev.match))
end

local group = vim.api.nvim_create_augroup('ssh_files', {})
vim.api.nvim_create_autocmd('BufReadCmd', { group = group, pattern = 'ssh://*', callback = read })
vim.api.nvim_create_autocmd('BufWriteCmd', { group = group, pattern = 'ssh://*', callback = write })

local function picker(title, finder, on_pick)
  local actions, state = require('telescope.actions'), require('telescope.actions.state')
  local conf = require('telescope.config').values
  require('telescope.pickers').new({}, {
    prompt_title = title,
    finder = finder,
    sorter = conf.generic_sorter({}),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(bufnr)
        -- scheduled: a picker opened from inside another one's action does not draw its results
        if entry then vim.schedule(function() on_pick(entry.value) end) end
      end)
      return true
    end,
  }):find()
end

-- Lists first, then opens the picker: a failing ssh (unknown host, no key, missing dir or fd)
-- shows its error instead of an empty picker.
function M.files(host, base)
  local cmd = vim.list_extend(vim.list_extend({}, ssh),
    { host, 'cd ' .. vim.fn.shellescape(base) .. ' && fd --type f --hidden --exclude .git' })
  vim.system(cmd, {}, vim.schedule_wrap(function(r)
    local files = vim.split(r.stdout or '', '\n', { trimempty = true })
    if r.code ~= 0 or #files == 0 then
      return vim.notify(('ssh_files: listing %s:%s failed: %s'):format(host, base,
        r.code ~= 0 and vim.trim(r.stderr) or 'no files'), vim.log.levels.ERROR)
    end
    picker(host .. ':' .. base, require('telescope.finders').new_table({ results = files }), function(file)
      vim.cmd.edit(vim.fn.fnameescape(('ssh://%s/%s/%s'):format(host, base, file)))
    end)
  end))
end

function M.pick()
  local bases = {}
  for host, paths in pairs(M.paths) do
    for _, p in ipairs(paths) do table.insert(bases, host .. ':' .. p) end
  end
  picker('ssh paths', require('telescope.finders').new_table({ results = bases }), function(base)
    M.files(base:match('^([^:]+):(.+)$'))
  end)
end

return M
