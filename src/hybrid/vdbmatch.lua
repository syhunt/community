require 'SyHybrid'

function vdbmatch(url,links)
	local r = slx.string.list:new()
	tab:loadx([['<html>
	<link rel="stylesheet" type="text/css" href="Resources.pak#Sandcat.css">
	<body>
	Loading, please wait...
	</body>
	</html>']])
	local search = osvdb_search(links,url)
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#listview.css">')
	r:add('<body>')
	r:add('<div class="container">')
	r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
	r:add('<tr><th width="80%">Link</th><th width="20%">OSVDB Matches</th></tr>')
	r:add(search)
	r:add('</table>')
	r:add('</div>')
	local j = {}
	j.title = 'VDB Match'
	j.icon = 'url(SyHybrid.scx#images\\icon_dbsearch.png)'
	j.html = r.text
	browser.newtabx(j)
	r:release()
end
