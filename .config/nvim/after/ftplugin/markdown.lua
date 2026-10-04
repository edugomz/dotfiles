-- render-markdown adds heading signs right after the buffer opens; with
-- signcolumn=auto the gutter then grows under already-placed images, shifting
-- the text 2 cells right of them. Keep the gutter width fixed from the start.
vim.opt_local.signcolumn = 'yes'

-- Open the ```mermaid block under the cursor in the browser, fitted to the window,
-- with wheel zoom, drag pan and +/-/reset controls.
local page = [[
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>%s</title>
<style>
  html, body { margin: 0; height: 100%%; background: #1e1e1e; }
  #diagram { margin: 0; height: 100%%; }
  #diagram svg { width: 100%%; height: 100%%; max-width: none !important; }
</style>
<script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.2/dist/svg-pan-zoom.min.js"></script>
</head>
<body>
<pre id="diagram">%s</pre>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs'
  mermaid.initialize({ startOnLoad: false, theme: 'dark' })
  await mermaid.run({ nodes: [document.getElementById('diagram')] })
  svgPanZoom('#diagram svg', { controlIconsEnabled: true, fit: true, center: true, minZoom: 0.1, maxZoom: 50 })
</script>
</body>
</html>
]]

local function mermaid_under_cursor()
  local node = vim.treesitter.get_node({ ignore_injections = true })
  while node and node:type() ~= 'fenced_code_block' do
    node = node:parent()
  end
  if not node then return nil end
  local info, source
  for child in node:iter_children() do
    if child:type() == 'info_string' then info = vim.treesitter.get_node_text(child, 0) end
    if child:type() == 'code_fence_content' then source = vim.treesitter.get_node_text(child, 0) end
  end
  if info and vim.trim(info) == 'mermaid' then return source end
end

vim.keymap.set('n', '<leader>mp', function()
  local source = mermaid_under_cursor()
  if not source then
    vim.notify('No mermaid block under the cursor', vim.log.levels.WARN)
    return
  end
  local escaped = source:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
  local path = vim.fn.tempname() .. '.html'
  vim.fn.writefile(vim.split(page:format(vim.fn.expand('%:t'), escaped), '\n'), path)
  vim.ui.open(path)
end, { buffer = true, desc = 'Mermaid: open block under cursor in browser' })
