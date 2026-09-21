-- Open the commit (or visual commit range) under the cursor in Diffview.
local function fmt(spec)
  return vim.fn['flog#Format'](spec)
end

vim.keymap.set('n', 'gd', function()
  local hash = fmt('%H')
  if hash ~= '' then
    vim.cmd('DiffviewOpen ' .. hash .. '^!')
  end
end, { buffer = true, desc = 'Diffview: commit under cursor' })

vim.keymap.set('x', 'gd', function()
  vim.cmd('normal! \27') -- leave visual so '< and '> are set
  -- Range yields every hash from '< to '>, newest first; diff oldest..newest.
  local hashes = vim.split(fmt([[%(h'<,'>)]]), ' ', { trimempty = true })
  if #hashes > 0 then
    vim.cmd('DiffviewOpen ' .. hashes[#hashes] .. '..' .. hashes[1])
  end
end, { buffer = true, desc = 'Diffview: selected commit range' })
