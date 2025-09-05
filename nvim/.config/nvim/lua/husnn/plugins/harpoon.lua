return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function ()
    local harpoon = require('harpoon')
    local keymap = vim.keymap

    keymap.set('n', '<leader>a',
      function ()
        harpoon:list():add()
      end,
      { desc = 'Add to harpoon' }
    )

    keymap.set('n', '<leader>e',
      function ()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      { desc = 'Toggle harpoon menu' }
    )

    keymap.set('n', '<leader>hh',
      function ()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      { desc = 'Toggle harpoon menu' }
    )

    keymap.set('n', '<leader>h1',
      function ()
        harpoon:list():select(1)
      end,
      { desc = 'Select harpoon buffer (1)' }
    )

    keymap.set('n', '<leader>h2',
      function ()
        harpoon:list():select(2)
      end,
      { desc = 'Select harpoon buffer (2)' }
    )

    keymap.set('n', '<leader>h3',
      function ()
        harpoon:list():select(3)
      end,
      { desc = 'Select harpoon buffer (3)' }
    )

    keymap.set('n', '<leader>h4',
      function ()
        harpoon:list():select(4)
      end,
      { desc = 'Select harpoon buffer (4)' }
    )

    harpoon.setup {}
  end
}
