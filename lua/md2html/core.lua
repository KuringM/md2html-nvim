local M = {}

-- escape HTML
local function escape_html(str)
	return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

-- inline math conversion
local function convert_inline_tex(text)
	if not text or text == "" then return "" end
	text = text:gsub("%$%$(.-)%$%$", function(content)
		return "\\[" .. content .. "\\]"
	end)
	text = text:gsub("()%$(.-)%$", function(_, content)
		if content:find("%$") then return "$" .. content .. "$"
		else return "\\(" .. content .. "\\)" end
	end)
	return text
end

-- inline formatting
local function format_inline(text)
	text = text:gsub("%*%*(.-)%*%*", "<strong>%1</strong>")
	text = text:gsub("%*(.-)%*", "<em>%1</em>")
	text = text:gsub("%[([^%]]-)%]%(([^%)]+)%)", '<a href="%2">%1</a>')
	text = text:gsub("!%[([^%]]-)%]%(([^%)]+)%)", '<img src="%2" alt="%1" />')
	text = text:gsub("%[%^([%w%d%-_]+)%]", '<sup id="ref-%1"><a href="#footnote-%1">[%1]</a></sup>')
	return convert_inline_tex(text)
end

-- markdown 转 html 主函数
function M.convert_md_to_html(lines)
	local html, i = {}, 1
	local in_list, list_type = false, nil
	local table_buf, footnotes = {}, {}

	local function parse_header(line)
		local level, content = line:match("^(#+)%s*(.*)")
		if level then
			local n = #level
			return string.format("<h%d>%s</h%d>", n, format_inline(content), n)
		end
	end

	local function parse_code_block(lines, start)
		local code = {}
		local i = start + 1
		while i <= #lines and not lines[i]:match("^```") do
			table.insert(code, escape_html(lines[i]))
			i = i + 1
		end
		return { "<pre>" .. table.concat(code, "\n") .. "</pre>" }, i
	end

	local function parse_math_block(lines, start)
		local math_lines, i = {}, start + 1
		while i <= #lines and not lines[i]:match("^%s*%$%$%s*$") do
			table.insert(math_lines, lines[i])
			i = i + 1
		end
		return {
			'<div class="math">', "\\[", table.concat(math_lines, "\n"), "\\]", "</div>"
		}, i
	end

	local function parse_table(rows)
		local html = { "<table>" }
		local header = rows[1]:gsub("^%|%s*", ""):gsub("%s*|%s*$", "")
		local cols = {}
		for col in header:gmatch("[^|]+") do
			table.insert(cols, "<th>" .. format_inline(col:match("^%s*(.-)%s*$")) .. "</th>")
		end
		table.insert(html, "<tr>" .. table.concat(cols) .. "</tr>")
		for i = 3, #rows do
			local line = rows[i]
			local cells = {}
			for cell in line:gsub("^%|%s*", ""):gsub("%s*|%s*$", ""):gmatch("[^|]+") do
				table.insert(cells, "<td>" .. format_inline(cell:match("^%s*(.-)%s*$")) .. "</td>")
			end
			table.insert(html, "<tr>" .. table.concat(cells) .. "</tr>")
		end
		table.insert(html, "</table>")
		return html
	end

	while i <= #lines do
		local line = lines[i]

		if line:match("^%s*$") then
			if in_list then
				table.insert(html, "</" .. list_type .. ">")
				in_list = false
			end
			if #table_buf > 0 then
				vim.list_extend(html, parse_table(table_buf))
				table_buf = {}
			end
			i = i + 1

		elseif line:match("^%[%^([%w%d%-_]+)%]:%s*(.*)") then
			local key, def = line:match("^%[%^([%w%d%-_]+)%]:%s*(.*)")
			footnotes[key] = def
			i = i + 1

		elseif line:match("^#+") then
			table.insert(html, parse_header(line))
			i = i + 1

		elseif line:match("^%s*%$%$%s*$") then
			local block, newi = parse_math_block(lines, i)
			vim.list_extend(html, block)
			i = newi + 1

		elseif line:match("^```") then
			local block, newi = parse_code_block(lines, i)
			vim.list_extend(html, block)
			i = newi + 1

		elseif line:match("^%s*|") and lines[i + 1] and lines[i + 1]:match("^%s*|?%s*[-:|%s]+|?%s*$") then
			repeat
				table.insert(table_buf, lines[i])
				i = i + 1
			until not lines[i] or lines[i]:match("^%s*$") or not lines[i]:match("^%s*|")

		elseif line:match("^%s*[%-%*+]%s+") or line:match("^%s*%d+%.%s+") then
			local ordered = line:match("^%s*%d+%.%s+") ~= nil
			local tag = ordered and "ol" or "ul"
			if not in_list or list_type ~= tag then
				if in_list then table.insert(html, "</" .. list_type .. ">") end
				table.insert(html, "<" .. tag .. ">")
				in_list, list_type = true, tag
			end
			local content = line:gsub("^%s*[%-%*+%d%.]+%s+", "")
			table.insert(html, "<li>" .. format_inline(content) .. "</li>")
			i = i + 1

		else
			if in_list then
				table.insert(html, "</" .. list_type .. ">")
				in_list = false
			end
			table.insert(html, "<p>" .. format_inline(line) .. "</p>")
			i = i + 1
		end
	end

	if in_list then table.insert(html, "</" .. list_type .. ">") end

	if next(footnotes) then
		table.insert(html, "<hr><h3>脚注</h3><ol>")
		for key, val in pairs(footnotes) do
			table.insert(html, string.format(
				'<li id="footnote-%s">%s <a href="#ref-%s">↩</a></li>',
				key, format_inline(val), key))
		end
		table.insert(html, "</ol>")
	end

	return html
end

return M
