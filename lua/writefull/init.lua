local open = io.open
local curl = require("plenary.curl")

local writefull_url = "https://nlp.writefull.ai/prompt"

local function read_writefull_token()
	local token
	local file = open(vim.fn.stdpath("data") .. "/writefull-token.txt", "rb")
	if not file then
		print("Plase run WritefullToken and provide a token")
		return nil
	end
	token = file:read("*all")
	file:close()
	return token:gsub("%s+", "")
end

local function get_preceding_chars(line, col)
	-- Get all lines
	local lines = vim.api.nvim_buf_get_lines(0, 0, line, false)

	-- Initialize character count
	local preceding_chars = 0

	-- Iterate through lines up to current line
	for i = 1, (#lines - 1) do
		preceding_chars = preceding_chars + string.len(lines[i]) + 1
	end
	preceding_chars = preceding_chars + (col - 1) -- adjust for current line and column

	return preceding_chars
end

local function writefull_rephrase(pos_start, pos_end)
	local token = read_writefull_token()
	if not token then
		return
	end

	pos_start = pos_start or vim.fn.getpos("v")
	pos_end = pos_end or vim.fn.getpos(".")

	local buff = vim.fn.join(vim.fn.getline(1, "$"), "\n")

	local _, pos_start_line, pos_start_col, _ = unpack(pos_start)
	local _, pos_end_line, pos_end_col, _ = unpack(pos_end)

	local char_start = get_preceding_chars(pos_start_line, pos_start_col)
	local char_end = get_preceding_chars(pos_end_line, pos_end_col)
	char_end = char_end + 1

	local request_body = {
		action = "rewrite_paraphrase",
		context = buff,
		selection = {
			["start"] = char_start,
			["end"] = char_end,
		},
	}

	local opts = {
		body = vim.fn.json_encode(request_body),
		headers = {
			content_type = "application/json",
			["Firebase-Token"] = token,
		},
	}

	local res = curl.post(writefull_url, opts)
	local res_body = vim.fn.json_decode(res.body)

	-- vim.api.nvim_echo({ { buff .. "\n" }, { tostring(char_start) .. ", " }, { tostring(char_end) } }, false, {})
	-- print(res.body)
	print(vim.fn.json_encode(res))
end

-- Define a custom command to trigger data fetch
vim.api.nvim_create_user_command("FetchData", writefull_rephrase, { nargs = "?" })
vim.api.nvim_create_user_command(
	"WritefullToken",
	"tabnew " .. vim.fn.stdpath("data") .. "/writefull-token.txt",
	{ nargs = "?" }
)
-- vim.api.nvim_set_keymap("v", "<leader>fd", ":FetchData<CR>", { silent = false })

vim.keymap.set("v", "<leader>wr", writefull_rephrase, { noremap = true })
