return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim'
  },
  keys = {
    { '<leader>l', '<cmd>Neotree toggle<cr>', desc = 'Toggle NeoTree' }
  },
  config = function ()
    require('neo-tree').setup({
      window = {
        position = 'right',
        mappings = {
          ['n'] = { "toggle_node", nowait = true }
        }
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true
        }
      }
    })
  end
}
