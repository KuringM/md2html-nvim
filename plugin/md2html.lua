vim.api.nvim_create_user_command("MdToHtml", function()
	local md2html = require("md2html.core")
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local html_body = md2html.convert_md_to_html(lines)

	local md_path = vim.api.nvim_buf_get_name(buf)
	local html_path = md_path:gsub("%.md$", ".html")
	local f = io.open(html_path, "w")
	if not f then
		print("❌ 无法写入 HTML 文件")
		return
	end

	f:write([[
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Markdown</title>
  <style>table,th,td{border:1px solid #ccc;border-collapse:collapse;padding:5px;}</style>
  <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
</head>
<body>
]])
	for _, l in ipairs(html_body) do
		f:write(l .. "\n")
	end
	f:write("</body>\n</html>")
	f:close()

	print("✅ 已生成 HTML 文件: " .. html_path)
end, {})
