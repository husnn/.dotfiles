return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim'
  },
  config = function ()
    local mason = require('mason')
    local mason_lspconfig = require('mason-lspconfig')

    mason.setup()

    mason_lspconfig.setup {
      ensure_installed = {
        'astro',
        'buf_ls',
        'clangd',
        'cssls',
        'gopls',
        'html',
        'jdtls',
        'lua_ls',
        'pyright',
        'tailwindcss',
        'terraformls',
        'ts_ls'
      },
      automatic_installation = true
    }
  end
}

