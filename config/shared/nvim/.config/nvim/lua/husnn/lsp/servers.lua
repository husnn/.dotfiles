-- Single source of truth for the LSP servers we use: mason installs them
-- (via the keys) and lspconfig configures them (via the settings values).
return {
  astro = {
    typescript = {}
  },
  buf_ls = {},
  clangd = {},
  cssls = {},
  gopls = {},
  html = {},
  jdtls = {},
  lua_ls = {
    diagnostics = { globals = { "vim" } }
  },
  pyright = {},
  tailwindcss = {},
  terraformls = {},
  ts_ls = {}
}
