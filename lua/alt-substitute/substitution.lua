local M = {}
local parameters = require("alt-substitute.process-parameters")
local regex = require("alt-substitute.regex")
--------------------------------------------------------------------------------

local warn = vim.log.levels.WARN
local hlgroup = "Substitute"

--------------------------------------------------------------------------------
---@param bufferLines string[]
---@param startLine number
---@param toSearch string lua pattern to search for
---@param toReplace string|nil nil means no highlight, will only get search position
---@param flags string
---@param regexFlavor string currently only lua
---@return table[] hlPositions
local function calculateHighlightPositions(bufferLines, startLine, toSearch, toReplace, flags, regexFlavor)
	local hlPositions = {}

	-- iterate lines
	for i, line in ipairs(bufferLines) do
		local lineIdx = startLine + i - 2

		-- search line for matches
		local matchesInLine = {}
		local startPos, endPos = 0, 0
		while true do
			startPos, endPos = regex.find(line, toSearch, endPos + 1, flags, regexFlavor)
			if not startPos then break end -- no more matches found
			table.insert(matchesInLine, { startPos = startPos, endPos = endPos })
			if not (flags:find("g")) then break end -- only one iteration when no `g` flag
		end

		-- iterate matches
		local previousShift = 0
		for ii, m in ipairs(matchesInLine) do
			-- if replacing, needs to consider shift in positions from previous
			-- matches in the same line
			if toReplace and toReplace ~= "" then
				-- stylua: ignore
				local lineWithSomeSubs = (regex.replace({ line }, toSearch, toReplace, ii, flags, regexFlavor))[1]
				local diff = (#lineWithSomeSubs - #line)
				m.startPos = m.startPos + previousShift
				m.endPos = m.endPos + diff
				previousShift = diff
			end
		end
		hlPositions[lineIdx] = matchesInLine
	end
	return hlPositions
end

-- https://neovim.io/doc/user/map.html#%3Acommand-preview
---@param opts table
---@param ns number namespace for the highlight
---@return 0|1|2 -- no preview|nosplit|split/nosplit
function M.preview(opts, ns, regexFlavor)
	local curBufNum = vim.api.nvim_get_current_buf()
	local line1, line2, bufferLines, toSearch, toReplace, flags = parameters.process(opts, curBufNum)

	-- without search value, there will be no useful preview
	if toSearch == "" then return 0 end 

	-- preview changes
	if toReplace and toReplace ~= "" then
		local newBufferLines = regex.replace(bufferLines, toSearch, toReplace, nil, flags, regexFlavor)
		vim.api.nvim_buf_set_lines(curBufNum, line1 - 1, line2, false, newBufferLines)
	end

	-- draw the highlights
	local hlPositions = calculateHighlightPositions(bufferLines, line1, toSearch, toReplace, flags, regexFlavor)
	for lineIdx, matchesInLine in pairs(hlPositions) do
		for _, m in pairs(matchesInLine) do
			vim.api.nvim_buf_add_highlight(curBufNum, ns, hlgroup, lineIdx, m.startPos - 1, m.endPos)
		end
	end

	return 1 -- 1 = always act as if inccommand=unsplit
end

---the substitution to perform when the commandline is confirmed with <CR>
---@param opts table
---@param showNotification boolean
---@param regexFlavor string currently only lua
function M.confirm(opts, showNotification, regexFlavor)
	local curBufNum = vim.api.nvim_get_current_buf()
	local line1, line2, bufferLines, toSearch, toReplace, flags = parameters.process(opts, curBufNum)
	local validFlags = "gfi"
	local invalidFlagsUsed = flags:find("[^" .. validFlags .. "]")

	if not toReplace then
		vim.notify("No replacement value given, cannot perform substitution.", warn)
		return
	elseif toReplace:find("%%$") then
		-- stylua: ignore
		vim.notify('A single "%" cannot be used as replacement value in lua patterns. \n(A literal "%" must be escaped as "%%".)', warn)
		return
	elseif toSearch == "" then
		vim.notify("Search string is empty.", warn)
		return
	end
	if invalidFlagsUsed then
		-- stylua: ignore
		vim.notify(('"%s" contains invalid flags, the only valid flags are "%s".\nInvalid flags have been ignored.'):format(flags, validFlags), warn)
	end

	local newBufferLines, totalReplacementCount =
		regex.replace(bufferLines, toSearch, toReplace, nil, flags, regexFlavor)
	vim.api.nvim_buf_set_lines(curBufNum, line1 - 1, line2, false, newBufferLines)
	if showNotification then
		vim.notify("Replaced " .. tostring(totalReplacementCount) .. " instances.")
	end
end

--------------------------------------------------------------------------------
return M
