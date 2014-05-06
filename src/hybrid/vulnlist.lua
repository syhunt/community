require 'SyHybrid'

VulnList = {
	title = 'Vulnerability List',
	icon = 'url(Syhunt.scx#images\\icon_dast.png)'
}

function VulnList:addinterface(p)
	p:add([[
	<select id="searchtype" size="1">
	<option value="none" SELECTED></OPTION>
	<option value="vulnname">Vulnerability Name</OPTION>
	<option value="cveid">CVE ID</OPTION>
	<option value="osvdbid">OSVDB ID</OPTION>
	<option value="ovalid">OVAL ID</OPTION>
	<option value="bid">Bugtraq ID</OPTION>
	</select>&nbsp;&nbsp;<input type="text" style="width:300px;" id="searchinput">&nbsp;&nbsp;<button onclick="VulnList:dosearch()">Search</button>
	<br><br>
	<widget type="select" style="padding:0;">
	<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>
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
	return pak_textfilecountln(pak,file)
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
	h = scl.stringlist:new()
	self:addinterface(h)
	self:addsection(h,'Search results for "'..scop.html.escape(searchtext)..'" ['..string.upper(searchtype)..']')
	h:add(vuln_search(searchtext,searchtype))
	self:closeinterface(h)
	tab:loadx(h.text)
	h:release()
	local ui = self.ui
	ui.searchinput.value = searchtext
	ui.searchtype.value = searchtype
end

function VulnList:loadtab()
	local NA = '<font color="gray">N/A</font>'
	h = scl.stringlist:new()
	self:addinterface(h)

	-- Name/Total/CWE/CVE/OSVDB/BID
	-- TODO: Convert this list to CSV
	self:addsection(h,'Application Checks')
	self:additem(h,'Backdoors',symini.getrescount('DYN_BDOORS'),NA,NA,NA,NA)
	self:additem(h,'Database Disclosure',symini.getrescount('DYN_BFORCE'),NA,NA,NA,NA)
	self:additem(h,'Extension Checking',symini.getrescount('DYN_BKPEXT'),NA,NA,NA,NA)
	self:additem(h,'Extra Files',symini.getrescount('DYN_XPDAT'),NA,NA,NA,NA)
	self:additem(h,'Suspicious Strings',symini.getrescount('DYN_SWORDS'),NA,NA,NA,NA)

	self:addsection(h,'Application Checks - Fault Injection')
	self:additem(h,'File Inclusion',symini.getrescount('DYN_CHK_FI'),NA,NA,NA,NA)
	self:additem(h,'XSS / Cross-Site Scripting',symini.getrescount('DYN_CHK_XSS'),'79',NA,NA,NA)
	self:additem(h,'XSS / Cross-Site Scripting (HTML5)',symini.getrescount('DYN_CHK_XSS5'),'79',NA,NA,NA)
	self:additem(h,'Directory Traversal',symini.getrescount('DYN_CHK_DT'),'98',NA,NA,NA)
	self:additem(h,'Remote Command Execution',symini.getrescount('DYN_CHK_RCE'),NA,NA,NA,NA)
	self:additem(h,'SQL Exposures',symini.getrescount('DYN_CHK_SQL'),'89',NA,NA,NA)
	self:additem(h,'SQL Injection',symini.getrescount('DYN_CHK_SQLI'),'89',NA,NA,NA)
	self:additem(h,'NoSQL Injection',symini.getrescount('DYN_CHK_NOSQLI'),NA,NA,NA,NA)
	self:additem(h,'Server-Side JavaScript Injection',symini.getrescount('DYN_CHK_SSJSI'),NA,NA,NA,NA)
	self:additem(h,'Arbitrary File Reading',symini.getrescount('DYN_CHK_AFR'),NA,NA,NA,NA)
	self:additem(h,'Path Disclosure',symini.getrescount('DYN_CHK_PD'),'200',NA,NA,NA)
	self:additem(h,'Information Disclosure',symini.getrescount('DYN_CHK_ID'),'200',NA,NA,NA)
	self:additem(h,'Directory Listing',symini.getrescount('DYN_CHK_DL'),NA,NA,NA,NA)
	self:additem(h,'Password Disclosure',symini.getrescount('DYN_CHK_PWD'),'472',NA,NA,NA)
	self:additem(h,'Default Account',symini.getrescount('DYN_CHK_DA'),NA,NA,NA,NA)
	self:additem(h,'Miscellaneous',symini.getrescount('DYN_CHK_ML'),NA,NA,NA,NA)
	self:additem(h,'IIS',symini.getrescount('DYN_CHK_IIS'),NA,NA,NA,NA)
	self:additem(h,'iPlanet',symini.getrescount('DYN_CHK_IPL'),NA,NA,NA,NA)
	self:additem(h,'Buffer Overflow',symini.getrescount('DYN_CHK_BO'),NA,NA,NA,NA)
	self:additem(h,'Internal IP Address Disclosure','1','212',NA,NA,NA)
	self:additem(h,'Default Welcome Page','1',NA,NA,NA,NA)
	self:additem(h,'WebDAV Enabled','1',NA,NA,NA,NA)
	self:additem(h,'PUT Method Enabled','1',NA,NA,NA,NA)
	self:additem(h,'TRACE Method Enabled','1',NA,NA,NA,NA)
	self:additem(h,'DELETE Method Enabled','1',NA,NA,NA,NA)
	self:additem(h,'TRACK Method Enabled','1',NA,NA,NA,NA)
	self:additem(h,'CONNECT Method Enabled','1',NA,NA,NA,NA)
	self:additem(h,'Cross Frame Scripting',symini.getrescount('DYN_CHK_CFS'),NA,NA,NA,NA)
	self:additem(h,'CRLF Injection',symini.getrescount('DYN_CHK_INJ'),'93',NA,NA,NA)
	self:additem(h,'Source Code Disclosure',symini.getrescount('DYN_CHK_SCD'),NA,NA,NA,NA)
	self:additem(h,'PHP Code Injection',symini.getrescount('DYN_CHK_PHPCI'),'74',NA,NA,NA)
	self:additem(h,'XPath Injection',symini.getrescount('DYN_CHK_XPT'),'91',NA,NA,NA)
	self:additem(h,'LDAP Injection',symini.getrescount('DYN_CHK_LDAP'),'90',NA,NA,NA)
	self:additem(h,'MX Injection',symini.getrescount('DYN_CHK_IMAPI'),'74',NA,NA,NA)
	self:additem(h,'Cookie Manipulation',symini.getrescount('DYN_CHK_CKM'),NA,NA,NA,NA)
	self:additem(h,'Unvalidated Redirect',symini.getrescount('DYN_CHK_UR'),'601',NA,NA,NA)

	self:addsection(h,'Source Checks')
	self:additem(h,'ASP',symini.getrescount('CODE_ASP'),NA,NA,NA,NA)
	self:additem(h,'Generic',symini.getrescount('CODE_GENERIC'),NA,NA,NA,NA)
	self:additem(h,'HTML',symini.getrescount('CODE_HTML'),NA,NA,NA,NA)
	self:additem(h,'JavaScript',symini.getrescount('CODE_JS'),NA,NA,NA,NA)
	self:additem(h,'JSP',symini.getrescount('CODE_JSP'),NA,NA,NA,NA)
	self:additem(h,'Perl',symini.getrescount('CODE_PL'),NA,NA,NA,NA)
	self:additem(h,'Python',symini.getrescount('CODE_PY'),NA,NA,NA,NA)
	self:additem(h,'PHP',symini.getrescount('CODE_PHP'),NA,NA,NA,NA)
	self:closeinterface(h)

	local j = {}
	j.title = self.title
	j.icon = self.icon
	j.table = 'VulnList.ui'
	j.html = h.text
	browser.newtabx(j)
	h:release()
end
