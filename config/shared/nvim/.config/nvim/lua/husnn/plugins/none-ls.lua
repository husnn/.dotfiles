return {
  'nvimtools/none-ls.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'jay-babu/mason-null-ls.nvim',
    'nvimtools/none-ls-extras.nvim'
  },
  config = function ()
    require("mason-null-ls").setup {
      ensure_installed = {
        'black',
        'eslint_d',
        'prettier'
      }
    }

    local null_ls = require('null-ls')
    local null_ls_utils = require('null-ls.utils')

    local formatting = null_ls.builtins.formatting

    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    null_ls.setup {
      root_dir = null_ls_utils.root_pattern('.git', 'package.json'),
      sources = {
        require('none-ls.diagnostics.eslint_d').with {
          condition = function (utils)
            return utils.root_has_file {
              '.eslintrc',
              '.eslintrc.json',
              '.eslintrc.cjs'
            }
          end
        },
        formatting.black,
        formatting.prettier
      },
      on_attach = function(current_client, bufnr)
        if current_client.supports_method('textDocument/formatting') then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format {
                filter = function (client)
                  return client.name == 'null-ls'
                end,
                bufnr = bufnr
              }
            end
          })
        end
      end
    }
  end
}

