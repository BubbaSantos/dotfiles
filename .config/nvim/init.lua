-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.api.nvim_create_user_command("CopyWithLines", function()
  -- Save current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Add line numbers
  local numbered_lines = {}
  for i, line in ipairs(lines) do
    table.insert(numbered_lines, string.format("%6d\t%s", i, line))
  end

  -- Join and copy to clipboard
  local content = table.concat(numbered_lines, "\n")
  vim.fn.setreg("+", content)

  print("Copied " .. #lines .. " lines with line numbers to clipboard")
end, {})

vim.keymap.set("n", "<leader>cl", ":CopyWithLines<CR>", { desc = "Copy with line numbers" })
