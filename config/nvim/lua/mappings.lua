require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>w", "<cmd>w<CR>", { desc = "save" })
map("n", "<leader>q", "<cmd>wq!<CR>", { desc = "save" })
map("n", "<leader>da", ":%d<CR>", { desc = "Delete all lines" })
map("n", "<leader>pa", "ggVGp", { desc = "Delete all lines" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
