local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Layout = require("nui.layout")
local event = require("nui.utils.autocmd").event

local baleia = require("baleia").setup({})

local function change_preview(input)
	local text_preview = Popup({
		enter = true,
		focusable = false,
		border = {
			style = "rounded",
		},
	})

	local options = Popup({
		enter = false,
		focusable = false,
		border = {
			style = "rounded",
		},
	})

	local layout = Layout(
		{
			position = "50%",
			size = {
				width = "80%",
				height = "60%",
			},
			relative = "editor",
		},
		Layout.Box({
			Layout.Box(text_preview, { size = "80%" }),
			Layout.Box(options, { size = "20%" }),
		}, { dir = "col" })
	)

	-- mount/open the component
	layout:mount()

	-- unmount component when cursor leaves buffer
	-- layout:on(event.BufLeave, function()
	-- 	layout:unmount()
	-- end)

	-- set content
	-- vim.api.nvim_buf_set_lines(text_preview.bufnr, 0, 1, false, { input })
	baleia.buf_set_lines(text_preview.bufnr, 0, 1, false, { input })
	vim.api.nvim_buf_set_lines(options.bufnr, 0, 1, false, { "(Y)es  (N)o  (R)etry" })

	text_preview:map("n", "y", function()
		print("Yes")
	end, {})
end

return {
	change_preview = change_preview,
}
