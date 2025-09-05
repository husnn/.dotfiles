return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    'hrsh7th/cmp-path',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'rafamadriz/friendly-snippets',
    'onsails/lspkind.nvim'
  },
  config = function ()
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end
      },
      completion = {
        completeopt = 'menu,menuone,preview,noselect'
      },
      mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = false }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { 'i', 's' })
      }),
      sources = {
        { name = 'luasnip' },
        { name = 'nvim_lsp' },
        { name = 'path' }
      },
      formatting = {
        format = require('lspkind').cmp_format {
          maxwidth = 50,
          ellipsis_char = '...'
        }
      },
      experimental = {
        ghost_text = true
      }
    }
  end
}
