return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    },
  },
  config = function ()
    local keymap = vim.keymap

    keymap.set('n', '<leader>ff', '<cmd>Telescope find_files hidden=true<cr>', { desc = 'Find files by names' })
    keymap.set('n', '<leader>fs', '<cmd>Telescope live_grep<cr>', { desc = 'Search in files' })
    keymap.set('n', '<leader>fc', '<cmd>Telescope grep_string<cr>', { desc = 'Find current word' })
    keymap.set('n', '<leader><space>', '<cmd>Telescope buffers<cr>', { desc = 'Show open buffers' })

    require('telescope').setup {
      defaults = {
        file_ignore_patterns = { ".git" }
      }
    }

    require('telescope').load_extension('fzf')
  end
}

