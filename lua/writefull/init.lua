local open = io.open
local curl = require("plenary.curl")
local dialog = require("writefull.dialog")
local wtoken = require("writefull.token")

local ansi_colors = {
	removed = {
		start = "\x1b[91m\x1b[9m",
		stop = "\x1b[39m\x1b[29m",
	},
	added = {
		start = "\x1b[92m",
		stop = "\x1b[39m",
	},
	unchanged = {
		start = "",
		stop = "",
	},
}

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

local function create_string_from_deltas(deltas)
	local output = ""
	for i, v in ipairs(deltas) do
		output = output .. ansi_colors[v.type].start .. v.value .. ansi_colors[v.type].stop
	end
	return output
end

local function rephrase(pos_start, pos_end)
	local token = wtoken.access_token_read()
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

	local res = curl.post(wtoken.writefull_url, opts)
	if res.status ~= 200 then
		error(
			"Error at retrieving rephrase data. Request data: "
				.. vim.fn.json_encode(opts)
				.. ". Response data: "
				.. vim.fn.json_encode(res)
		)
	end
	local res_body = vim.fn.json_decode(res.body)

	-- vim.api.nvim_echo({ { buff .. "\n" }, { tostring(char_start) .. ", " }, { tostring(char_end) } }, false, {})
	-- print(res.body)
	print('Rephrase retrieved and put in " register')
	vim.fn.setreg('"', res_body.result[1].value)

	local output = create_string_from_deltas(res_body.result[1].deltas)
	output = output:gsub("\n", "\\n")
	print(output)
	dialog.change_preview(output)
end

-- Define a custom command to trigger data fetch
-- vim.api.nvim_create_user_command("WritefullRephrase", rephrase, { nargs = "?" })
vim.api.nvim_create_user_command("WritefullToken", "tabnew " .. wtoken.token_path_refresh, { nargs = "?" })
-- vim.api.nvim_set_keymap("v", "<leader>fd", ":FetchData<CR>", { silent = false })

vim.keymap.set("v", "<leader>wr", rephrase, { noremap = true })
