ReportMaker = {
	title = 'Report Maker',
	icon = 'url(SyHybrid.scx#images\\16\\saverep.png)',
	default_template = 'Standard',
	msg_nosession = 'You need to start a session before generating a report',
	session_name = '',
	session_dir = '',
	xmllist = '',
	template_action = '',
	template_name = ''
}

function ReportMaker:can_open_report()
	local ui = self.ui
	return ui.openrep.value
end

function ReportMaker:do_tpl_item(name)
	local e = self.ui.element
	e:select('input[tplname="'..name..'"]')
	if self.template_action == 'get_default' then
		e.value=rm:getincludeitem(name)
	end
	if self.template_action == 'set_user' then
		rm:setincludeitem(name,e.value)
	end
end

function ReportMaker:do_template(action)
	self.template_action = action
	self:do_tpl_item('Organization Logo')
	self:do_tpl_item('User Notes')
	self:do_tpl_item('Session Details')
	self:do_tpl_item('Charts')
	self:do_tpl_item('Flash Content')
	self:do_tpl_item('Dynamic Content')
	self:do_tpl_item('Compliance Info')
	self:do_tpl_item('Compliance (OWASP PHP Top 5)')
	self:do_tpl_item('Compliance (OWASP Top 10)')
	self:do_tpl_item('Compliance (PCI)')
	self:do_tpl_item('Compliance (SANS Top 20)')
	self:do_tpl_item('Vulnerabilities')
	self:do_tpl_item('High Risk Vulnerabilities')
	self:do_tpl_item('Medium Risk Vulnerabilities')
	self:do_tpl_item('Low Risk Vulnerabilities')
	self:do_tpl_item('Minimal Risk Vulnerabilities')
	self:do_tpl_item('Request')
	self:do_tpl_item('Response (Header)')
	self:do_tpl_item('Response')
	self:do_tpl_item('Link List')
	self:do_tpl_item('Email List')
end

function ReportMaker:set_template(name)
  require 'Repmaker'
	self.template_name = name
	rm = SyRepmaker:new()
	rm.Template = name
	self:do_template('get_default')
	rm:release()
end

function ReportMaker:gen_report()
  require 'Repmaker'
	rm = SyRepmaker:new()
	local ui = self.ui
	local filename = app.savefile(rm.Filter,'html',session_getsessionsdir()..'Report_'..self.session_name)
	local reptitle = ui.report_title.value
	debug.print('file:'..filename)
	if filename ~= '' then
		rm.Filename = filename
		rm.SessionName = self.session_name
		rm.SessionDir = self.session_dir
		rm.Template = self.template_name
		self:do_template('set_user')
		if reptitle ~= '' then rm.ReportTitle = reptitle end
		tab.status = 'Generating report...'
		rm:savereport()
		debug.print('report saved')
		if self:can_open_report() then
			browser.newtab(filename)
			--browser.setactivepage('browser')
			--tab:gotourl(filename)
		end
		tab.status = ''
	end
	rm:release()
	debug.print('report maker released')
end

function ReportMaker:edit_sesfile(f)
	local ui = self.ui
	ui.editors:setattrib('xmlfile',f)
	ui.editors:setstyle('display','none')
	ui.vulneditor:setstyle('display','none')
	local xml = GXMLIniList:new()
	xml:loadfromfile(self.session_dir..f)
	type = xml:getvalue('type')
	ui.editorinclude.value = true
	if xml:getvalue('Include') == 'No' then
		ui.editorinclude.value = false
	end
	if type == 'Host' then
		ui.editors:setstyle('display','block')
	end
	if type == 'Port' then
		ui.editors:setstyle('display','block')
	end
	if type == 'Vulnerability' then
		ui.editors:setstyle('display','block')
		ui.vulneditor:setstyle('display','block')
		ui.vuln_checkname.value = xml:getvalue('Check Name')
		ui.vuln_risk.value = xml:getvalue('Risk')
		ui.vuln_location.value = xml:getvalue('Location')
		ui.vuln_params.value = xml:getvalue('Params')
		ui.vuln_description.value = xml:getvalue('Description')
		ui.vuln_recommendations.value = xml:getvalue('Recommendations')
		ui.vuln_usernotes.value = xml:getvalue('User Notes')
	end
	xml:release()
end

function ReportMaker:update_field_fromcheckbox(tag,inputname,field)
	local ui = self.ui
	local e = self.ui.element
	local fn = ui.editors:getattrib('xmlfile')
	local xml = GXMLIniList:new()
	xml:loadfromfile(self.session_dir..fn)
	e:select(tag..'[id="'..inputname..'"]')
	local newval = e.value
	if newval == true then
		xml:setvalue(field,'Yes') else
		xml:setvalue(field,'No')
	end
	xml:savetofile(self.session_dir..fn)
	xml:release()
end

function ReportMaker:update_field(tag,inputname,field)
	local ui = self.ui
	local e = self.ui.element
	local fn = ui.editors:getattrib('xmlfile')
	local xml = GXMLIniList:new()
	xml:loadfromfile(self.session_dir..fn)
	e:select(tag..'[id="'..inputname..'"]')
	xml:setvalue(field,e.value)
	xml:savetofile(self.session_dir..fn)
	xml:release()
end

function ReportMaker:do_searchclear()
	local ui = self.ui
	ui.searchtext.value = ''
	self:do_search()
end

function ReportMaker:do_search()
	local ui = self.ui
	local e = self.ui.element
	local xml = GXMLIniList:new()
	local xmlfiles = slx.string.loop:new()
	xmlfiles:load(self.xmllist)
	local searchfield = ui.searchfield.value
	local searchtype = ui.searchtype.value
	local searchtext = ui.searchtext.value
	if ui.searchmcase.value == 'False' then
		searchtext = string.lower(searchtext)
	end
	while xmlfiles:parsing() do
		found = false
		xml:loadfromfile(self.session_dir..xmlfiles.current)
		local fieldvalue = xml:getvalue(searchfield)
		if ui.searchmcase.value == 'False' then
			fieldvalue = string.lower(fieldvalue)
		end
		if searchtype == "contains" then
			if slx.string.occur(fieldvalue,searchtext) ~= 0 then found = true end
		end
		if searchtype == "doesn't contain" then
			if slx.string.occur(fieldvalue,searchtext) == 0 then found = true end
		end
		if searchtype == "is" then
			if fieldvalue == searchtext then found = true end
		end
		if searchtype == "isn't" then
			if fieldvalue ~= searchtext then found = true end
		end
		if searchtype == "begins with" then
			if slx.string.beginswith(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "ends with" then
			if slx.string.endswith(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "matches regex" then
			if slx.re.match(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "doesn't match regex" then
			if slx.re.match(fieldvalue,searchtext) == false then found = true end
		end
		if searchtype == "matches wildcard" then
			if slx.string.match(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "doesn't match wildcard" then
			if slx.string.match(fieldvalue,searchtext) == false then found = true end
		end
		if searchtext == "" then
			found = true
		end
		e:select('tr[name="xrm_'..xmlfiles.curindex..'"]')
		if found == true then
			e:setstyle('display','block') else
			e:setstyle('display','none')
		end
	end
	xml:release()
	xmlfiles:release()
end

function ReportMaker:add_field(type,name,inputname)
	if type == 'input' then
		r:add([[<tr role="option"><td><b>]]..name..[[</b></td><td><INPUT type="text" id="]]..inputname..[[" onchange="ReportMaker:update_field('input',']]..inputname..[[',']]..name..[[')" style="width:80%;"></td></tr>]])
	end
	if type == 'plaintext' then
		r:add([[<tr role="option"><td><b>]]..name..[[</b></td><td><plaintext id="]]..inputname..[[" onchange="ReportMaker:update_field('plaintext',']]..inputname..[[',']]..name..[[')" style="width:80%;height:100px;"></plaintext></td></tr>]])
	end
end

function ReportMaker:add_repdata()
	r:add('<div class="container">')
	r:add('Filter:')
	r:add([[
	<select id="searchfield" size="1">
	<option value="none" SELECTED></option>
	<option value="Check ID">Check ID</option>
	<option value="Check Name">Check Name</option>
	<option value="Description">Description</option>
	<option value="Host">Host</option>
	<option value="Location">Location</option>
	<option value="Port">Port</option>
	<option value="References (BID)">References (BID)</option>
	<option value="References (CVE)">References (CVE)</option>
	<option value="References (OSVDB)">References (OSVDB)</option>
	<option value="Request">Request</option>
	<option value="Response">Response</option>
	<option value="Response (Header)">Response (Header)</option>
	<option value="Risk">Risk</option>
	<option value="User Notes">User Notes</option>
	</select>
	]])
	r:add([[<select id="searchtype" size="1">
	<option value="contains" selected>contains</option>
	<option value="doesn't contain">doesn't contain</option>
	<option value="is">is</option>
	<option value="isn't">isn't</option>
	<option value="begins with">begins with</option>
	<option value="ends with">ends with</option>
	<option value="matches regex">matches regex</option>
	<option value="doesn't match regex">doesn't match regex</option>
	<option value="matches wildcard">matches wildcard</option>
	<option value="doesn't match wildcard">doesn't match wildcard</option>
	</select>
	<input type="text" id="searchtext" style="width:200px;">
	<input type="checkbox" id="searchmcase">Match case&nbsp;&nbsp;
	<button onclick="ReportMaker:do_search()">Apply Filter</button>&nbsp;
	<button onclick="ReportMaker:do_searchclear()">Clear</button>
	<br><br>]])
	r:add('<widget type="select" style="padding:0;">')
	r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
	r:add('<tr><th width="10%">Entry Type</th><th width="90%">Short Description</th></tr>')
	local xml = GXMLIniList:new()
	local xmlfiles = slx.string.loop:new()
	xmlfiles:load(self.xmllist)
	while xmlfiles:parsing() do
		xml:loadfromfile(self.session_dir..xmlfiles.current)
		type = xml:getvalue('type')
		desc = xml:getvalue('host')
		if type == 'Vulnerability' then
			desc = slx.html.escape(xml:getvalue('check name'))
		end
		if type == 'Port' then
			desc = xml:getvalue('host')..':'..xml:getvalue('port')
		end
		r:add([[<tr name="xrm_]]..xmlfiles.curindex..[[" role="option" onclick="ReportMaker:edit_sesfile(']]..xmlfiles.current..[[')"><td>]]..type..[[</td><td>]]..desc..[[</td></tr>]])
	end
	xmlfiles:release()
	xml:release()
	r:add('</table>')
	r:add('</widget>')
	r:add('</div>')
	r:add('<div id="editors" xmlfile="" style="display:none">')
	r:add([[<button type="checkbox" id="editorinclude" onclick="ReportMaker:update_field_fromcheckbox('input','editorinclude','Include')">Include</button>]])
	r:add('</div>')
	-- vuln editor
	r:add('<div id="vulneditor" class="container" style="display:none">')
	r:add('<widget type="select" style="padding:0;">')
	r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
	r:add('<tr><th width="10%"></th><th width="90%"></th></tr>')
	self:add_field('input','Check Name','vuln_checkname')
	self:add_field('input','Risk','vuln_risk')
	self:add_field('input','Location','vuln_location')
	self:add_field('input','Params','vuln_params')
	self:add_field('plaintext','Description','vuln_description')
	self:add_field('plaintext','Recommendations','vuln_recommendations')
	self:add_field('plaintext','User Notes','vuln_usernotes')
	r:add('</table>')
	r:add('</widget>')
	r:add('</div>')
	-- vuln editor end
end

function ReportMaker:get_xmlfield(field)
	local xml = GXMLIniList:new()
	xml:loadfromfile(self.session_dir..'_Main.xrm')
	local notes = xml:getvalue(field)
	xml:release()
	return notes
end

function ReportMaker:save_xmlfield(field,inputname)
	local e = self.ui.element
	local xml = GXMLIniList:new()
	local fn = self.session_dir..'_Main.xrm'
	xml:loadfromfile(fn)
	e:select('plaintext[id="'..inputname..'"]')
	local notes = e.value
	xml:setvalue(field,notes)
	xml:savetofile(fn)
	xml:release()
end

function ReportMaker:show_options()
	local tabs_begin = [[
	<div class="tabs">
	<div class="strip" role="page-tab-list">
	<div panel="panel-id2" selected role="page-tab">General</div>
	<div panel="panel-id1" role="page-tab">Editor</div>
	</div>
	]]
	local rep_options = [[
	Choose a report template:<br>
	<input type="radio" id="template" onclick="ReportMaker:set_template('Standard')" checked>Standard<br>
	<input type="radio" id="template" onclick="ReportMaker:set_template('Compliance')">Compliance<br>
	<input type="radio" id="template" onclick="ReportMaker:set_template('Complete')">Complete<br><br>
	The following items will be included:<br>
	<div style="width:100%%;height:100%%;">
	<widget type="select" style="padding:0;">
	<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>
	<tr><td></td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Organization Logo" checked>Organization Logo</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="User Notes" checked>User Notes</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Session Details" checked>Session Details</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Charts" checked>Charts</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Flash Content">Flash Content</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Dynamic Content" checked>Dynamic Content</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Compliance Info">Compliance Info</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Compliance (OWASP PHP Top 5)" checked>Compliance (OWASP PHP Top 5)</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Compliance (OWASP Top 10)" checked>Compliance (OWASP Top 10)</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Compliance (PCI)" checked>Compliance (PCI)</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Compliance (SANS Top 20)" checked>Compliance (SANS Top 20)</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Vulnerabilities" checked>Vulnerabilities</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="High Risk Vulnerabilities" checked>High Risk Vulnerabilities</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Medium Risk Vulnerabilities" checked>Medium Risk Vulnerabilities</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Low Risk Vulnerabilities" checked>Low Risk Vulnerabilities</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Minimal Risk Vulnerabilities" checked>Minimal Risk Vulnerabilities</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Request" checked>Request</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Response (Header)">Response (Header)</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Response">Response</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Link List">Link List</td></tr>
	<tr role="option"><td><input type="checkbox" tplname="Email List">Email List</td></tr>
	</table>
	</widget>
	</div>
	]]
	self.xmllist = slx.dir.getfilelist(self.session_dir..'*.xrm')
	local report_title = 'Syhunt Scanner Report'

	r = slx.string.list:new()
	r:add('<meta id="element">')
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#listview.css">')
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#tabs.css">')
	r:add(tabs_begin)
	r:add('<div name="panel-id2" class="tab" selected>') -- panel 2
	r:add('<table width="100%" height="100%"><tr>')
	r:add('<td width="40%" valign="top">')
	r:add('<fieldset style="height:100%;"><legend style="color:black">Report Details for: '..self.session_name..'</legend>')
	r:add('<div style="width:*;padding-right:5px;">')
	r:add('Report Title:<br><input type="text" id="report_title" style="width:*;" value="'..slx.html.escape(report_title)..'"><br><br>')
	r:add([[Notes:<br><plaintext id="usernotes" style="width:*;height:200px;" onchange="ReportMaker:save_xmlfield('user notes','usernotes')">]]..slx.html.escape(ReportMaker:get_xmlfield('user notes'))..[[</plaintext><br>]])
	r:add([[Footer:<br><plaintext id="footer" style="width:*;height:200px;" onchange="ReportMaker:save_xmlfield('footer','footer')">]]..slx.html.escape(ReportMaker:get_xmlfield('footer'))..[[</plaintext>]])
	r:add('</div>')
	r:add('</fieldset>')
	r:add('</td>')
	r:add('<td width="60%" valign="top">')
	r:add('<fieldset style="height:100%;"><legend style="color:black">Template</legend>')
	r:add(rep_options)
	r:add('</fieldset>')
	r:add('</td>')
	r:add('</tr></table><br>')
	r:add('</div>') -- panel2 end
	r:add('<div name="panel-id1" class="tab">') -- panel 1
	self:add_repdata()
	r:add('</div>') -- panel 1 end
	r:add('</div>') -- tabs end
	r:add('<p align="right"><input type="checkbox" id="openrep" checked>Open report after generation&nbsp;&nbsp;&nbsp;&nbsp;<button onclick="ReportMaker:gen_report()">Save Report</button></p>')
	local j = {}
	j.title = self.title..' - '..self.session_name
	j.icon = self.icon
	j.table = 'ReportMaker.ui'
	j.toolbar = 'SyHybrid.scx#hybrid\\repmaker\\toolbar.html'
	j.tag = self.title
	j.html = r.text
	browser.newtabx(j)
	r:release()
	self:set_template(self.default_template)
end

function ReportMaker:loadtab(s)
	require 'SyHybrid'
	self.session_name = s
	self.session_dir = session_getsessionsdir()..'\\'..s..'\\'
	if self.session_name == '' then app.showmessage(self.msg_nosession)
else self:show_options()
end
end

function ReportMaker:newtab()
local s = tab:userdata_get('session')
if s ~= '' then
	self:loadtab(s)
else
	app.showmessage(self.msg_nosession)
end
end
