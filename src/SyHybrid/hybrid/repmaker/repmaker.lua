ReportMaker = {
	title = 'Report Maker',
	icon = 'url(SyHybrid.scx#images\\16\\saverep.png)',
	default_template = 'Standard',
	default_template_sort = 'CVSS3',
	msg_nosession = 'You need to start a session before generating a report',
	session_name = '',
	session_dir = '',
	xmllist = '',
	template_action = '',
	template_name = '',
	template_sort = ''
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
	local ro = ctk.string.loop:new()
	ro:load(rm.IncludeList)
	while ro:parsing() do
	  self:do_tpl_item(ro.current)
    end
	ro:release()
end

function ReportMaker:get_template()
	local ro = ctk.string.loop:new()
	local out = ctk.string.list:new()
	local outlist = ''
	ro:load(rm.IncludeList)
	while ro:parsing() do
	  local e = self.ui.element
	  e:select('input[tplname="'..ro.current..'"]')
	  if e.value == true then
	    out:add(ro.current..'=1')
	  else
	    out:add(ro.current..'=0')
	  end
    end
    outlist = out.text
    out:release()
	ro:release()
	return outlist
end

function ReportMaker:set_template(name)
	self.template_name = name
	rm = symini.repmaker:new()
	rm.Template = name
	self:do_template('get_default')
	rm:release()
end

function ReportMaker:set_templatesort(name)
	self.template_sort = name
end

function ReportMaker:gen_report()
    ctk.dir.create(symini.info.outputdir)
	rm = symini.repmaker:new()
	local ui = self.ui
	local filename = app.savefile(rm.Filter,'html',symini.info.outputdir..'Report_'..self.session_name)
	local reptitle = ui.report_title.value
	debug.print('file:'..filename)
	if filename ~= '' then
	    local script = SyHybrid:getfile('hybrid/repmaker/repgentask.lua')
  		local j = ctk.json.object:new()
		j.filename = filename
		j.session_name = self.session_name
		j.session_dir = self.session_dir
		j.template_name = self.template_name
		j.template_sort = self.template_sort
		j.template_selection = self:get_template()
		--self:do_template('set_user')
		j.reptitle = reptitle
		j.canopenreport = self:can_open_report()
		tid = tab:runtask(script,tostring(j))
		j:release()
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
	local xmlfiles = ctk.string.loop:new()
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
			if ctk.string.occur(fieldvalue,searchtext) ~= 0 then found = true end
		end
		if searchtype == "doesn't contain" then
			if ctk.string.occur(fieldvalue,searchtext) == 0 then found = true end
		end
		if searchtype == "is" then
			if fieldvalue == searchtext then found = true end
		end
		if searchtype == "isn't" then
			if fieldvalue ~= searchtext then found = true end
		end
		if searchtype == "begins with" then
			if ctk.string.beginswith(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "ends with" then
			if ctk.string.endswith(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "matches regex" then
			if ctk.re.match(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "doesn't match regex" then
			if ctk.re.match(fieldvalue,searchtext) == false then found = true end
		end
		if searchtype == "matches wildcard" then
			if ctk.string.match(fieldvalue,searchtext) == true then found = true end
		end
		if searchtype == "doesn't match wildcard" then
			if ctk.string.match(fieldvalue,searchtext) == false then found = true end
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
	r:add('<table name="reportview" width="100%" cellspacing=0px fixedrows=1>')
	r:add('<tr><th width="10%">Entry Type</th><th width="90%">Short Description</th></tr>')
	local xml = GXMLIniList:new()
	local xmlfiles = ctk.string.loop:new()
	xmlfiles:load(self.xmllist)
	while xmlfiles:parsing() do
		xml:loadfromfile(self.session_dir..xmlfiles.current)
		type = xml:getvalue('type')
		desc = xml:getvalue('host')
		if type == 'Vulnerability' then
			desc = ctk.html.escape(xml:getvalue('check name'))
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
	r:add('<table name="reportview" width="100%" cellspacing=0px fixedrows=1>')
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

function ReportMaker:get_jsonfield(field)
	local j = ctk.json.object:new()
	local fn = self.session_dir..'_Main.jrm'
	if ctk.file.exists(fn) then
	  j:loadfromfile(fn)
	end
	local notes = j:getvalue('data.'..field,'')
	j:release()
	return notes
end

function ReportMaker:save_jsonfield(field,inputname)
	local e = self.ui.element
	local j = ctk.json.object:new()
	local fn = self.session_dir..'_Main.jrm'
	if ctk.file.exists(fn) then
	  j:loadfromfile(fn)
	end
	e:select('plaintext[id="'..inputname..'"]')
	local notes = e.value
	j['data.'..field] = notes
	j:savetofile(fn)
	j:release()
end

function ReportMaker:show_options()
	local rm = symini.repmaker:new()
	local options = rm.IncludeList
	local templates = rm.TemplateList
	rm:release()
	
	local tabs_begin = [[
	<div class="tabs">
	<div class="strip" role="page-tab-list">
	<div panel="panel-id2" selected role="page-tab">General</div>
	<!div panel="panel-id1" role="page-tab"><!Editor><!/div>
	</div>
	]]
	local rep_options_html = [[
	Choose a report template:<br>
	%reltemplates%
	<br>
	The following items will be included:<br>
	<div style="width:100%%;height:220px;">
	<widget type="select" style="padding:0;">
	<table name="reportview" width="100%" cellspacing=0px fixedrows=1>
	<tr><td></td></tr>
	%reloptions%
	</table>
	</widget>
	</div>
	]]
	
	local rep_options = ctk.string.list:new()
	local rep_templates = ctk.string.list:new()
	local ro = ctk.string.loop:new()
	local checked = ''
	ro:load(options)
	while ro:parsing() do
	  rep_options:add('<tr role="option"><td><input type="checkbox" tplname="'..ro.current..'">'..ro.current..'</td></tr>')
	end
	ro:load(templates)
	while ro:parsing() do
	  checked = ''
      if ro:curgetvalue('d') == '1' then
        checked = 'checked=checked'
      end
	  if ro:curgetvalue('t') ~= '' then
	    rep_templates:add('<input type="radio" id="template" onclick="ReportMaker:set_template([['..ro:curgetvalue('n')..']])" '..checked..'>'..ro:curgetvalue('t')..'<br>')
	  end
	end	
	rep_options_html = ctk.string.replace(rep_options_html, '%reloptions%', rep_options.text)
	rep_options_html = ctk.string.replace(rep_options_html, '%reltemplates%', rep_templates.text)
	ro:release()
	rep_options:release()
	rep_templates:release()
	
	self.xmllist = ctk.dir.getfilelist(self.session_dir..'*.xrm')
	local report_title = 'Syhunt Scan Report'

	r = ctk.string.list:new()
	r:add('<meta id="element">')
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#listview.css">')
	r:add('<link rel="stylesheet" type="text/css" href="Common.pak#tabs.css">')
	r:add(tabs_begin)
	r:add('<div name="panel-id2" class="tab" selected>') -- panel 2
	r:add('<table width="100%" height="100%"><tr>')
	r:add('<td width="40%" valign="top">')
	r:add('<fieldset><legend style="color:black">Report Details for: '..self.session_name..'</legend>')
	r:add('<div style="width:*;padding-right:5px;">')
	r:add('Report Title:<br><input type="text" id="report_title" style="width:*;" value="'..ctk.html.escape(report_title)..'"><br><br>')
	r:add([[Notes:<br><plaintext id="usernotes" style="width:*;height:120px;" onchange="ReportMaker:save_jsonfield('user_notes','usernotes')">]]..ctk.html.escape(ReportMaker:get_jsonfield('user_notes'))..[[</plaintext><br>]])
	r:add([[Footer:<br><plaintext id="footer" style="width:*;height:120px;" onchange="ReportMaker:save_jsonfield('footer','footer')">]]..ctk.html.escape(ReportMaker:get_jsonfield('footer'))..[[</plaintext>]])
	r:add('</div>')
	r:add('</fieldset>')
	r:add('Choose a vulnerability sorting method:<br>')
	r:add([[<input type="radio" id="templatesort" onclick="ReportMaker:set_templatesort('CVSS3')" checked>CVSS3<br>]])
	r:add([[<input type="radio" id="templatesort" onclick="ReportMaker:set_templatesort('CVSS2')">CVSS2<br>]])
	r:add([[<input type="radio" id="templatesort" onclick="ReportMaker:set_templatesort('4STEP')">Four Step (High, Medium, Low, Info)<br><br>]])
	r:add('</td>')
	r:add('<td width="60%" valign="top">')
	r:add('<fieldset style="height:100%;"><legend style="color:black">Template</legend>')
	r:add(rep_options_html)
	r:add('</fieldset>')
	r:add('</td>')
	r:add('</tr></table><br>')
	r:add('</div>') -- panel2 end
	r:add('<div name="panel-id1" class="tab">') -- panel 1
	--self:add_repdata()
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
	self:set_templatesort(self.default_template_sort)
end

function ReportMaker:loadtab(s)
   require 'SyMini'
   self.session_name = s
   self.session_dir = symini.info.sessionsdir..'\\'..s..'\\'
   if self.session_name == '' then
     app.showmessage(self.msg_nosession)
   else
     self:show_options()
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
