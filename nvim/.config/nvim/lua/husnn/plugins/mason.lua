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
      ensure_installed = vim.tbl_keys(require('husnn.lsp.servers')),
      automatic_installation = true
    }
  end
}

