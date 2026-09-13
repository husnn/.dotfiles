local opt = vim.opt

-- Line numbering
opt.relativenumber = true
opt.number = true

-- Appearance
opt.signcolumn = 'yes'
opt.termguicolors = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Navigation
opt.mouse = 'a'

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- Use the system clipboard only when a provider is available. Headless/core
-- machines retain normal registers without warnings or GUI dependencies.
local clipboard = (vim.fn.has('macunix') == 1 and vim.fn.executable('pbcopy') == 1)
  or ((vim.env.WAYLAND_DISPLAY or '') ~= '' and vim.fn.executable('wl-copy') == 1 and vim.fn.executable('wl-paste') == 1)
  or ((vim.env.DISPLAY or '') ~= '' and (vim.fn.executable('xclip') == 1 or vim.fn.executable('xsel') == 1))
if clipboard then opt.clipboard:append('unnamedplus') end

-- Windows
opt.splitright = true
opt.splitbelow = true

-- Misc
opt.swapfile = false
opt.undofile = true

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*'
})

-- Automatically save when buffer loses focus
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost' }, {
  callback = function()
    local fn = vim.fn.expand('%')
    if vim.bo.modified and not vim.bo.readonly and fn ~= '' and vim.bo.buftype == '' then
      vim.api.nvim_command('silent write')
      vim.api.nvim_echo({{ 'Saved '..fn..' at '..vim.fn.strftime('%T') }}, true, {})
      vim.fn.timer_start(1000, function ()
        vim.api.nvim_echo({{ '' }}, false, {})
      end)
    end
  end,
})
