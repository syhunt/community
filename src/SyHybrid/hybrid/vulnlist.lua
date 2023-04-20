VulnList = {
	title = 'Vulnerability List',
	icon = 'url(PenTools.scx#images\\icon_dast.png)'
}

function VulnList:addinterface(p)
	p:add([[
	<div style="display:none">
	<select id="searchtype" size="1">
	<option value="none" SELECTED></OPTION>
	<option value="vulnname">Vulnerability Name</OPTION>
	<option value="cveid">CVE ID</OPTION>
	<option value="osvdbid">OSVDB ID</OPTION>
	<option value="ovalid">OVAL ID</OPTION>
	<option value="bid">Bugtraq ID</OPTION>
	</select>&nbsp;&nbsp;<input type="text" style="width:300px;" id="searchinput">&nbsp;&nbsp;<button onclick="VulnList:dosearch()">Search</button>
	<br><br>
	</div>
	<widget type="select" style="padding:0;">
	<table name="reportview" width="100%" cellspacing=0px fixedrows=1>
	<tr><th width="50%">Vulnerability Name/Category</th><th width="10%">Total</th><th width="10%">CWE</th><th width="10%">CVE</th><th width="10%">OSVDB</th><th width="10%">BID</th><th></th></tr>
	]])
end

function VulnList:closeinterface(p)
	p:add([[</table>
	</widget>]])
end

function VulnList:gettd(s)
	s = s or ''
	r = '<td>'..s..'</td>'
	return r
end

function VulnList:getcount(pak,file)
	return symini.pak_textfilecountln(pak,file)
end

function VulnList:additem(p,Name,Total,CWE,CVE,OSVDB,BID)
	p:add('<tr role="option">'..self:gettd(Name)..self:gettd(Total)..self:gettd(CWE)..self:gettd(CVE)..self:gettd(OSVDB)..self:gettd(BID)..'</tr>')
end

function VulnList:addsection(p,Name)
	p:add([[
	<tr bgcolor="gray">
	<td width="100%"><font color="white"><b>]]..Name..[[</b></font></td>
	<td></td>
	<td></td>
	<td></td>
	<td></td>
	<td></td>
	<td></td>
	</tr>]])
end

function VulnList:dosearch()
	local searchtext = ''
	local searchtype = ''
	if self.ui ~= nil then
		searchtext = self.ui.searchinput.value
		searchtype = self.ui.searchtype.value
	end
	html = [[<html><body>Searching...</body></html>]]
	tab:loadx(html)
	h = ctk.string.list:new()
	self:addinterface(h)
	self:addsection(h,'Search results for "'..ctk.html.escape(searchtext)..'" ['..string.upper(searchtype)..']')
	h:add(vuln_search(searchtext,searchtype))
	self:closeinterface(h)
	tab:loadx(h.text)
	h:release()
	local ui = self.ui
	ui.searchinput.value = searchtext
	ui.searchtype.value = searchtype
end

function VulnList:addchecks(options)
	local NA = '<font color="gray">N/A</font>'
	local opt = {}
	local cwe = ''
	local slp = ctk.string.loop:new()
	slp:load(options)
	while slp:parsing() do
		opt = symini.getoptdetails(slp.current, true)
		if opt.level == 1 then
		  opt.caption = '&nbsp;&nbsp;&nbsp;&nbsp;<font color="navy">'..opt.caption..'</font>'
		end
		cwe = tostring(opt.cwe)
		if cwe == '0' then
		 cwe = NA
		end
		self:additem(h,opt.caption,opt.count,cwe,NA,NA,NA)
	end
	slp:release()
end

function VulnList:loadtab()
	h = ctk.string.list:new()
	self:addinterface(h)
	-- Name/Total/CWE/CVE/OSVDB/BID
	local ds = symini.dynamic:new()
	ds:start()
	self:addsection(h,'Application Checks')
	self:addchecks(ds.options_checks)
	self:addsection(h,'Application Checks - Fault Injection')
	self:addchecks(ds.options_checksinj)
	ds:release()

    local cs = symini.code:new()
	self:addsection(h,'Source Checks')
	--self:addchecks(cs.options_checks)
	--self:addchecks(cs.options_checksmap)
	self:additem(h,'ASP',symini.getrescount('CODE_CHK_ASP'),NA,NA,NA,NA)
	self:additem(h,'Generic',symini.getrescount('CODE_CHK_GENERIC'),NA,NA,NA,NA)
	self:additem(h,'HTML',symini.getrescount('CODE_CHK_HTML'),NA,NA,NA,NA)
	self:additem(h,'C',symini.getrescount('CODE_CHK_C'),NA,NA,NA,NA)
	self:additem(h,'JavaScript (Client-Side)',symini.getrescount('CODE_CHK_JS_CLIENT'),NA,NA,NA,NA)
	self:additem(h,'JavaScript (Server-Side)',symini.getrescount('CODE_CHK_JS_SERVER'),NA,NA,NA,NA)
	self:additem(h,'Java',symini.getrescount('CODE_CHK_JSP'),NA,NA,NA,NA)
	self:additem(h,'Lua',symini.getrescount('CODE_CHK_LUA'),NA,NA,NA,NA)
	self:additem(h,'Pascal',symini.getrescount('CODE_CHK_PAS'),NA,NA,NA,NA)
	self:additem(h,'Perl',symini.getrescount('CODE_CHK_PL'),NA,NA,NA,NA)
	self:additem(h,'PHP',symini.getrescount('CODE_CHK_PHP'),NA,NA,NA,NA)	
	self:additem(h,'Python',symini.getrescount('CODE_CHK_PY'),NA,NA,NA,NA)
    self:additem(h,'Ruby',symini.getrescount('CODE_CHK_RUBY'),NA,NA,NA,NA)
	self:additem(h,'Swift',symini.getrescount('CODE_CHK_SWIFT'),NA,NA,NA,NA)	
	cs:release()
	
	local icy = symini.breach:new()
	icy:start()
	self:addsection(h,'Breach Checks')
	self:addchecks(icy.options_checks)
	icy:release()	
	
	
	self:closeinterface(h)
	local j = {}
	j.title = self.title
	j.icon = self.icon
	j.table = 'VulnList.ui'
	j.html = h.text
	browser.newtabx(j)
	h:release()
end
