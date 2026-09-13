return {
  'wojciech-kulik/xcodebuild.nvim',
  enabled = function()
    if vim.fn.has('macunix') ~= 1 or vim.fn.executable('xcodebuild') ~= 1 then
      return false
    end
    -- /usr/bin/xcodebuild also exists with only Command Line Tools selected.
    local result = vim.system({ 'xcodebuild', '-version' }, { text = true }):wait(3000)
    return result.code == 0 and (result.stdout or ''):match('^Xcode ') ~= nil
  end,
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter'
  },
  config = function ()
    vim.keymap.set('n', '<leader>X', '<cmd>XcodebuildPicker<cr>', { desc = 'Show Xcodebuild Actions' })

    vim.keymap.set('n', '<leader>xb', '<cmd>XcodebuildBuild<cr>', { desc = 'Build Project' })
    vim.keymap.set('n', '<leader>xr', '<cmd>XcodebuildBuildRun<cr>', { desc = 'Build & Run Project' })

    require('xcodebuild').setup {}
  end
}
