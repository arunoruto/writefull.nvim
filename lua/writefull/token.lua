local open = io.open
local curl = require("plenary.curl")

local writefull_url = "https://nlp.writefull.ai/prompt"
local writefull_auth_url = "https://auth.writefull.ai/v2/user/idToken"

local token_path_refresh = vim.fn.stdpath("data") .. "/writefull-refresh-token.txt"
local token_path_access = vim.fn.stdpath("data") .. "/writefull-access-token.txt"

local function refresh_token_read()
	local token
	local file = open(token_path_refresh, "rb")
	if not file then
		print("Plase run WritefullToken and provide a token")
		return nil
	end
	token = file:read("*all")
	file:close()
	return token:gsub("%s+", "")
end

local function access_token_get()
	local token = refresh_token_read()
	local opts = {
		body = vim.fn.json_encode({
			refreshToken = token,
		}),
		headers = {
			content_type = "application/json",
		},
	}
	local res = curl.post(writefull_auth_url, opts)
	if res.status ~= 200 then
		error("Error at retrieving access token: " .. vim.fn.json_encode(res.body))
	end
	local data = {
		access_token = vim.fn.json_decode(res.body).access_token,
		expires_in = vim.fn.json_decode(res.body).expires_in,
		timestamp = os.time(os.date("!*t")),
	}
	local file = open(token_path_access, "w")
	if not file then
		error("Cannot create file at " .. token_path_access)
	end
	file:write(vim.fn.json_encode(data))
	file:close()
	return data.access_token
end

local function access_token_read()
	local data
	local file = open(token_path_access, "rb")
	if not file then
		print("No refresh token file found")
		return nil
	end
	data = file:read("*all")
	file:close()
	data = vim.fn.json_decode(data)
	local timestamp = os.time(os.date("!*t"))
	if timestamp > data.timestamp + data.expires_in then
		print("Token has expired. Getting new one!")
		return access_token_get()
	end
	return data.access_token
end

return {
	token_path_refresh = token_path_refresh,
	writefull_url = writefull_url,
	access_token_read = access_token_read,
	refresh_token_read = refresh_token_read,
}
