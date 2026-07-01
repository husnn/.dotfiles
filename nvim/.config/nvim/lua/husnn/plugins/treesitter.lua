local languages = {
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
  'markdown_inline',
  'python',
  'rust',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml'
}

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  event = { 'BufReadPre', 'BufNewFile' },
  build = ':TSUpdate',
  dependencies = {
    'windwp/nvim-ts-autotag'
  },
  config = function()
    -- Install/refresh parsers (no-op for parsers already present).
    require('nvim-treesitter').install(languages)

    -- Highlighting and indentation are enabled per-buffer via `vim.treesitter`
    -- on the main branch, rather than a `highlight`/`indent` module table.
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match) or args.match
        if vim.treesitter.language.add(lang) then
          vim.treesitter.start(args.buf, lang)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end
    })

    require('nvim-ts-autotag').setup {
      opts = {
        enable_close_on_slash = false
      }
    }
  end
}
