vim.g.mapleader = ' '

local keymap = vim.keymap

keymap.set('i', 'jj', '<ESC>', { desc = 'Exit insert mode' })

keymap.set('n', '<leader>sh', '<C-w>s', { desc = 'Split window horizontally' })
keymap.set('n', '<leader>sv', '<C-w>v', { desc = 'Split window vertically' })
keymap.set('n', '<leader>sx', '<cmd>close<CR>', { desc = 'Close current split' })

keymap.set('n', 'x', '"_x', { desc = 'Delete char without copying' })
keymap.set('n', 'X', '"_d', { desc = 'Delete command without copying' })

