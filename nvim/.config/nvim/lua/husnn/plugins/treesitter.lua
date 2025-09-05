return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPre', 'BufNewFile' },
  build = ':TSUpdate',
  dependencies = {
    'windwp/nvim-ts-autotag'
  },
  config = function ()
    require('nvim-treesitter.configs').setup {
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<c-space>',
          node_incremental = '<c-space>',
          scope_incremental = false,
          node_decremental = '<M-space>'
        }
      },
      autotag = {
        enable = true,
        enable_close_on_slash = false
      },
      ensure_installed = {
        'astro',
        'bash',
        'c',
        'cpp',
        'css',
        'dockerfile',
        'gitignore',
        'go',
        'html',
        'javascript',
        'json',
        'lua',
        'markdown',
        'python',
        'rust',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml'
      }
    }
  end
}

