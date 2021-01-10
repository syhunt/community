--require 'SyHybrid'

SpiderLinks = {}

function SpiderLinks:showsessionlinks(sessionname)
	local s = SC4WSession:new()
	s:load(sessionname)
	if s:getvalue('target_type') == 'Host(s)' then
		SpiderLinks:showhostlinks(sessionname,s:getvalue('targets'),s:getvalue('ports'))
	end
	s:release()
end

function SpiderLinks:getlinklist(sessionname,host,port)
	local inifilename = session_getsessionsdir()..sessionname..'\\'..host..' ['..port..']_Scanner.xml'
	local links = xmlinifile_readstring(inifilename,'Lists','Links','')
	return links
end

function SpiderLinks:findmatch()
	local ui = self.ui
	SyHybrid:dofile('hybrid/vdbmatch.lua')
	local host = ui.data:getattrib('host')
	local port = ui.data:getattrib('port')
	local session = ui.data:getattrib('session')
	local links = self:getlinklist(session,host,port)
	vdbmatch(ctk.url.genfromhost(host,port),links)
end

function SpiderLinks:openurl(url)
	browser.setactivepage('browser')
	url = ctk.convert.hextostr(url)
	tab:gotourl(url)
end

function SpiderLinks:showhostlinks(sessionname,host,port)
	browser.bottombar:loadx('<img src="res:activity.gif">')

	local inifilename=session_getsessionsdir()..sessionname..'\\'..host..' ['..port..']_Scanner.xml'
	local links = ctk.string.loop:new()
	local scanned_links = ctk.string.loop:new()
	local folders = ctk.string.loop:new()
	links:load(xmlinifile_readstring(inifilename,'Lists','Links',''))
	scanned_links:load(xmlinifile_readstring(inifilename,'Lists','Scnnd',''))
	folders:load(xmlinifile_readstring(inifilename,'Lists','Fldrs',''))

	local r = ctk.string.list:new()
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#listview.css">')
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#tabs.css">')
	r:add('<div class="tabs">')
	r:add('<div class="strip" role="page-tab-list">')
	r:add('<div panel="panel-id2" selected role="page-tab">General</div>')
	r:add('<div panel="panel-id1" role="page-tab">All Links</div>')
	r:add('</div>')
	r:add('<div name="panel-id1" class="tab">') -- panel 1
	r:add('<div class="container">')
	r:add('<table name="reportview" width="100%" cellspacing=0px fixedrows=1>')
	r:add('<tr><th width="80%">Link</th><th width="20%">Status</th></tr>')

	while links:parsing() do
		local link_desc = ctk.html.escape(links.current)
		local url = ctk.url.genfromhost(host,port)..links.current
		local url_hex = ctk.convert.strtohex(url)
		url = ctk.html.escape(url)
		local urlext = ctk.url.crack(url).fileext
		if scanned_links:indexof(links.current) == -1 then
			r:add('<tr><td><img class="shell-icon" filename="'..urlext..'"><a href="#" onclick="SpiderLinks:openurl([['..url_hex..']])">'..link_desc..'</a></td><td>Pending Analysis...</td></tr>')
		else
			r:add('<tr><td><img class="shell-icon" filename="'..urlext..'"><a href="#" onclick="SpiderLinks:openurl([['..url_hex..']])">'..link_desc..'</a></td><td>Done.</td></tr>')
		end
	end

	r:add('</table>')
	r:add('</div>')
	r:add('</div>') -- panel 1 end
	r:add('<div name="panel-id2" class="tab" selected>') -- panel 2
	r:add('<fieldset><legend style="color:black">Crawling Results</legend>')
	r:add('Total of links: '..links.count..'<br>')
	r:add('Crawled: '..scanned_links.count..'<br>')
	r:add('Folders: '..folders.count)
	r:add('</fieldset>')
	r:add('</div>') -- panel2 end
	r:add('</div>') -- tabs
	--r:add('<br><table width="100%"><tr>')
	--r:add('<td align="right"><button name="findmatch" onclick="SpiderLinks:findmatch()">Find Match</button></td>')
	--r:add('</tr></table>')
	r:add('<div id="data"></div>')

	browser.bottombar:loadx(r.text,'SpiderLinks.ui')
	local ui = self.ui
	ui.data:setattrib('host',host)
	ui.data:setattrib('port',port)
	ui.data:setattrib('session',sessionname)

	links:release()
	scanned_links:release()
	folders:release()
	r:release()
end
