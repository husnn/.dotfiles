return {
  'christoomey/vim-tmux-navigator',
  config = function()
    vim.g.tmux_navigator_save_on_switch = 0
    vim.g.tmux_navigator_disable_when_zoomed = 1
  end
}

