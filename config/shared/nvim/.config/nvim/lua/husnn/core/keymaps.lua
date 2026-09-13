vim.g.mapleader = ' '

local keymap = vim.keymap

keymap.set('i', 'jj', '<ESC>', { desc = 'Exit insert mode' })

keymap.set('n', '<leader>sh', '<C-w>s', { desc = 'Split window horizontally' })
keymap.set('n', '<leader>sv', '<C-w>v', { desc = 'Split window vertically' })
keymap.set('n', '<leader>sx', '<cmd>close<CR>', { desc = 'Close current split' })

keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save current buffer' })

keymap.set('n', 'x', '"_x', { desc = 'Delete char without copying' })
keymap.set('n', 'X', '"_d', { desc = 'Delete command without copying' })

-- Copy relative path
vim.keymap.set('n', '<leader>cp', ':let @+ = expand("%")<CR>', { desc = 'Copy relative file path' })

-- Copy absolute path
vim.keymap.set('n', '<leader>cf', ':let @+ = expand("%:p")<CR>', { desc = 'Copy absolute file path' })

