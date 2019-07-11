SessionManager = {
 title = 'Session Manager'
}

function SessionManager:setsessionstatus(sesname,status)
  local ses = symini.session:new()
  ses.name = sesname
  ses:setvalue('Status', status)
  ses:release()
end

function SessionManager:submitselected_vulns(trackername)
  local list = self:getlistofchecked_vulns(true)
  if list == '' then
    app.showmessage('You must select at least 1 vulnerability.')
  else
    local sl = ctk.string.list:new()
    sl.text = list
    if sl.count == 1 then
      -- no need to launch external task
      TrackerManager:SubmitIssue_FromVulnFile(trackername, sl.text) 
    else
      -- launch external task to submit multiple issues
      TrackerManager:SubmitIssue_FromVulnFileList(trackername, list) 
    end
    sl:release()
  end
end

function SessionManager:gettrackermenuitems()
  local list = TrackerManager:GetIssueTrackerList()
  local menu = ctk.string.list:new()
  local slp = ctk.string.loop:new()
  slp:load(list)
  while slp:parsing() do
    local name = slp.current
    local name_hex = ctk.convert.strtohex(name)
    local app = TrackerManager:GetTrackerApp(name)
    if app ~= '' then
      menu:add('<li onclick="SessionManager:submitselected_vulns(ctk.convert.hextostr([['..name_hex..']]))">Issue Tracker: '..ctk.html.escape(name)..' ('..app:upper()..')</li>')
    end
  end
  local menuhtml = menu.text
  menu:release()
  slp:release()
  return menuhtml
end

function SessionManager:add_sessiondetails(r, sesname, iscomparison)
  local details = symini.getsessiondetails(sesname)
  local stfontcolor = 'black'
  if details.vulncount ~= '0' then 
    stfontcolor = 'red'
  else
    stfontcolor = 'green'
  end
  r:add('<fieldset><legend style="color:black">'..sesname..'</legend>')
  r:add('Date: '..details.datetime..'<br>')
  r:add('Target(s): '..details.targetdesc..'<br>')
  r:add('Hunt Method: '..details.huntmethod..'<br>')
  r:add('Vulnerability Count: '..details.vulncount..'<br>')
  r:add('Status: <font color='..stfontcolor..'><b>'..details.resultsdesc..'</b></font>')
  r:add('<p align="left">')
  if iscomparison == false then
    r:add([[<button type="selector" menu="#trackerlist-items" style="width:60px;">Send To</button>]])
    r:add([[<menu id="trackerlist-items" style="display:none;">]])
    r:add(self:gettrackermenuitems())
    r:add([[</menu>]])  
  end
  r:add('</p>')
  r:add('<p align="right">')
  r:add([[<button onclick="ReportMaker:loadtab(']]..sesname..[[')">Generate Report</button>]])
  if iscomparison == false then
    r:add([[<button onclick="SessionManager:delsession(']]..sesname..[[')">Delete Session</button>]])
  end
  r:add('</p>')
  r:add('</fieldset><br>')
end

function SessionManager:show_sessiondetails(sesname)
 local details = symini.getsessiondetails(sesname)
 local sesdir = symini.info.sessionsdir
 local cursesdir = sesdir..'\\'..sesname..'\\'
 local vfilename_list = ctk.string.list:new()
 local r = ctk.string.list:new()
 local hasvuln = false
  r:add('<style>'..SyHybrid:getfile('hybrid/sesman/sesman.css')..'</style>')
  self:add_sessiondetails(r, sesname, false)
  
  r:add('Vulnerabilities: (Double-click an item for more details)')
  r:add('<div style="width:100%%;height:100%%;">')
  r:add('<widget type="select" style="padding:0;">')
  r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
  r:add('<tr><th width="20%">Description</th><th width="30%">Location</th><th width="20%">Affected Param(s)</th><th width="10%">Line(s)</th><th width="10%">Risk</th></tr>')
  l = ctk.string.loop:new()
  v = ctk.string.loop:new()
  l:load(ctk.dir.getfilelist(cursesdir..'*_Vulns.log'))
  while l:parsing() do
   v:load(ctk.file.getcontents(cursesdir..l.current))
   while v:parsing() do
    hasvuln = true
    local vfilename = v:curgetvalue('f')
    local vfilename_full_hex = ctk.convert.strtohex(cursesdir..v:curgetvalue('f'))
    local vname=ctk.html.escape(v:curgetvalue('vname'))
    local vpath=ctk.html.escape(v:curgetvalue('vpath'))
    local vpars=ctk.html.escape(v:curgetvalue('vpars'))
    local vrisk=v:curgetvalue('vrisk')
    local ricon = 'SyHybrid.scx#images/16/risk_'..vrisk..'.png'
    local vpath_desc = vpath
    local vpath_hex = ctk.convert.strtohex(v:curgetvalue('vpath'))
    vfilename_list:add(vfilename)
    if details.huntmethod == 'Source Code Scan' then
      vpath_desc = ctk.string.after(vpath_desc,'http://127.0.0.1')
    end
    r:add('<tr role="option" ondblclick="SyhuntDynamic:EditVulnDetails(ctk.convert.hextostr([['..vfilename_full_hex..']]))"><td><input type="checkbox" vrisk="'..vrisk..'" vfilename="'..vfilename..'"><img .lvfileicon src="'..ricon..'">&nbsp;'..vname..'</td><td><a href="#" onclick="browser.showurl(ctk.convert.hextostr([['..vpath_hex..']]))">'..vpath_desc..'</a></td><td>'..vpars..'</td><td>'..v:curgetvalue('vlns')..'</td><td>'..vrisk..'</td></tr>')
   end
  end
  v:release()
  l:release()
  
  r:add('</table>')
  r:add('</widget>')
  r:add('</div>')
  
  local j = {}
  j.title = 'Session Details - '..sesname
  if hasvuln == false then
    j.icon = self:get_session_icon(details)
  else
    j.icon = 'url(Resources.pak#16/icon_engerror.png)'
  end
  j.html = r.text
  j.toolbar = 'SyHybrid.scx#hybrid\\sesman\\toolbar_vulns.html'
  if browser.newtabx(j) ~= 0 then
    tab:userdata_set('session', sesname) 
    tab:userdata_set('sessiondir',cursesdir)
    tab:userdata_set('vfilename_list',vfilename_list.text)
  end
  r:release()
  vfilename_list:release()
end

function SessionManager:checkuncheckall_vulns(state,risk)
 local e = self.ui.element
 local boolstate = false
 if state==1 then boolstate=true end
 local p = ctk.string.loop:new()
 p:load(tab:userdata_get('vfilename_list',''))
 while p:parsing() do
  e:select('input[vfilename="'..p.current..'"]')
  if risk ~= nil then
    if e:getattrib('vrisk') == risk then
      e.value = boolstate
    end
  else
    e.value = boolstate
  end
 end
 p:release()
end

function SessionManager:getlistofchecked_vulns(fullfilename)
 local sl = ctk.string.list:new()
 local e = self.ui.element
 local state = false
 local sesdir = tab:userdata_get('sessiondir','')
 fullfilename = fullfilename or false
  local p = ctk.string.loop:new()
  p:load(tab:userdata_get('vfilename_list',''))
  while p:parsing() do
   e:select('input[vfilename="'..p.current..'"]')
   state=e.value
   if state==true then
    local name = p.current
    if fullfilename == true then
      name = sesdir..name
    end
    sl:add(name)
   end
  end
  local checkedlist = sl.text  
  p:release()
  sl:release()
  return checkedlist
end

function SessionManager:save_comparison(basesesname,secondsesname)
  local sesdir = symini.info.sessionsdir
  local fn = 'Comparison '..basesesname..'vs'..secondsesname..'.html'
  local srcfile = sesdir..basesesname..'\\'..fn
  local destfile = app.savefile('Comparison results (*.html)|*.html','html',fn)
  if destfile ~= '' then  
    ctk.file.copy(srcfile, destfile)
    browser.newtab(destfile)
  end
end

function SessionManager:comparesessions(basesesname,secondsesname)
  local bdetails = symini.getsessiondetails(basesesname)
  local sdetails = symini.getsessiondetails(secondsesname)
  local sesdir = symini.info.sessionsdir
  local bothcode = false
  local r = ctk.string.list:new()
  
  if bdetails.huntmethod == sdetails.huntmethod then
    if bdetails.huntmethod == 'Source Code Scan' then
      bothcode = true
    end
  end
  
  r:add('<html>')
  r:add('<head>')
  r:add('<title>Syhunt Session Comparison Results</title>')
  r:add('<style>'..SyHybrid:getfile('hybrid/sesman/sesman.css')..'</style>')
  r:add('<!--repstyle-->')
  r:add('</head>')
  r:add('<body>')
  r:add('<table width="100%"><tr><td width="45%">')
  self:add_sessiondetails(r, basesesname, true)
  r:add('</td><td>&nbsp;<b>VS</b>&nbsp;</td><td width="45%">')
  self:add_sessiondetails(r, secondsesname, true)
  r:add('</td></tr></table>')

  r:add('Vulnerabilities:')
  r:add('<div style="width:100%%;height:100%%;">')
  r:add('<widget type="select" style="padding:0;">')
  r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
  r:add('<tr><th width="20%">Description</th><th width="30%">Location</th><th width="20%">Affected Param(s)</th><th width="10%">Line(s)</th><th width="10%">Risk</th><th width="10%">Comparison Status</th></tr>')
  v = ctk.string.loop:new()
  v:load(symini.comparesessions(basesesname,secondsesname))
   while v:parsing() do
    local vname=ctk.html.escape(v:curgetvalue('vname'))
    local vpath=ctk.html.escape(v:curgetvalue('vpath'))
    local vpars=ctk.html.escape(v:curgetvalue('vpars'))
    local vpath_desc = vpath
    local vpath_hex = ctk.convert.strtohex(v:curgetvalue('vpath'))
    local bgcolor = '#eeeeee'
    if bothcode == true then
      vpath_desc = ctk.string.after(vpath_desc,'http://127.0.0.1')
    end
    if v:curgetvalue('cmpstat') == 'removed' then
      bgcolor = '#f3dddf'
    end
    if v:curgetvalue('cmpstat') == 'added' then
      bgcolor = '#ecf7ea'
    end
    r:add('<tr role="option" bgcolor="'..bgcolor..'"><td>'..vname..'</td><td><a href="#" outhref="'..vpath..'" onclick="browser.showurl(ctk.convert.hextostr([['..vpath_hex..']]))">'..vpath_desc..'</a></td><td>'..vpars..'</td><td>'..v:curgetvalue('vlns')..'</td><td>'..v:curgetvalue('vrisk')..'</td><td>'..v:curgetvalue('cmpstat')..'</td></tr>')
   end
  v:release()
  r:add('</table>')
  r:add('</widget>')
  r:add('</div>')
  r:add('<p align="right"><button onclick="SessionManager:save_comparison([['..basesesname..']],[['..secondsesname..']])">Save Comparison As...</button></p>')
  r:add('</body>')
  r:add('</html>')
  
  local j = {}
  j.title = 'Session Comparison - '..basesesname..' vs '..secondsesname
  j.icon = 'url(SyHybrid.scx#images\\16\\diff.png)'
  j.html = r.text
  browser.newtabx(j)

  local repstyle = [[
  <style>
  body { border:15px; font:normal 12px Tahoma; }
  button { display:none; }
  </style>
  ]]
  r.text = ctk.string.replace(r.text, '<!--repstyle-->',repstyle)
  r.text = ctk.string.replace(r.text, '<a href="#" outhref','<a target="_out" href')
  r.text = ctk.string.replace(r.text, 'onclick="browser.showurl','xonclick="browser.showurl')
  r:savetofile(sesdir..basesesname..'\\Comparison '..basesesname..'vs'..secondsesname..'.html')  
  r:release()
end

function SessionManager:comparechecked()
 local e = self.ui.element
 local repdir=symini.info.sessionsdir
 local state = false
 local p = ctk.string.loop:new()
 local sl = ctk.string.list:new()
 p:load(ctk.dir.getdirlist(repdir))
 while p:parsing() do
   e:select('input[session="'..p.current..'"]')
   state=e.value
   if state==true then
    sl:add(p.current)
   end
  end
 if sl.count == 2 then
   self:comparesessions(sl:get(0),sl:get(1))
 else
   app.showmessage('Two sessions must be selected!')
 end
 sl:release()
 p:release()
end

function SessionManager:load_session(name)
 require "SyMini"
 local ses = symini.session:new()
 ses.name = name
 local launcher = ses:getvalue('launcher')
 if launcher == 'Syhunt Code' then
  SyhuntCode:LoadSession(name)
 elseif launcher == 'Syhunt Insight' then
  SyhuntInsight:LoadSession(name)
 else
  SessionManager:show_sessiondetails(name)
 end
 ses:release()
end

function SessionManager:checkuncheckall(state)
 local e = self.ui.element
 local repdir=symini.info.sessionsdir
 local boolstate = false
 if state==1 then boolstate=true end
 local p = ctk.string.loop:new()
 p:load(ctk.dir.getdirlist(repdir))
 while p:parsing() do
  e:select('input[session="'..p.current..'"]')
  e.value = boolstate
 end
 p:release()
end

function SessionManager:get_ports(s)
 if s ~= '' then
  return ' ('..s..')'
 else
  return ''
 end
end

function SessionManager:getcounticon(i)
 function getnumberext(n)
  if n < 10 then
   n = '0'..tostring(n)
  elseif n < 21 then
   n = tostring(n)
  else
   n = '20-plus'
  end
  return n
 end
 
 local icon = ''
 if i == '0' then 
  icon = 'Resources.pak#16/icon_blank.png'
 else
  icon = 'SyHybrid.scx#images/16/counter/notification-counter-'..getnumberext(tonumber(i))..'.png'
 end
 return icon
end

function SessionManager:get_session_icon(details)
 local icon = 'Resources.pak#16/icon_help.png'
 if details.vulncount ~= '0' then 
   icon = 'Resources.pak#16/icon_engerror.png'
 else
   icon = 'SyHybrid.scx#images/16/shield_tick.png'
 end
 if details.status == 'Canceled' then icon = 'Resources.pak#16/icon_stop.png' end
 if details.status == 'Paused' then icon = 'Resources.pak#16/icon_pause.png' end
 if details.status == 'Unknown' then icon = 'Resources.pak#16/icon_help.png' end
 if details.status == 'Scanning' then icon = 'Resources.pak#16/icon_run.png' end  
 return icon
end

function SessionManager:add_session(r, sesname)
 local details = symini.getsessiondetails(sesname)
 local sesnamehex = ctk.convert.strtohex(sesname)
 local icon = self:get_session_icon(details)
 
 r:add('<tr role="option" style="context-menu: selector(#menu'..sesnamehex..');" ')
 r:add([[ondblclick="SessionManager:load_session(']]..sesname..[[')" ]])
 r:add('>')
 r:add('<td><input type="checkbox" session="'..sesname..'"><img .lvfileicon src="'..icon..'">&nbsp;'..details.datetime..' ('..sesname..')</td>')
 if details.sourcedir ~= '' then
  r:add('<td>'..details.sourcedir..'</td>')
 elseif details.targetfile ~= '' then
  r:add('<td>'..details.targetfile..'</td>')
 else
  r:add('<td>'..ctk.html.escape(details.targets)..self:get_ports(details.ports)..'</td>')
 end
 r:add('<td>'..details.huntmethod..'</td>')
 r:add('<td>'..details.resultsdesc..'&nbsp;<img .lvfileicon src="'..self:getcounticon(details.vulncount)..'"></td>')
 r:add('<menu.context id="menu'..sesnamehex..'">')
 r:add([[<li style="foreground-image: url(SyHybrid.scx#images\16\saverep.png);" onclick="ReportMaker:loadtab(']]..sesname..[[')">Generate Report</li>]])
 r:add([[<li onclick="SessionManager:show_sessiondetails(']]..sesname..[[')">View Vulnerabilities</li>]])
 r:add([[<li onclick="SessionManager:load_session(']]..sesname..[[')">Load In New Tab</li>]])
 r:add('<hr/>')
 r:add([[<li onclick="SessionManager:export_session(']]..sesname..[[')">Export Session As...</li>]]) 
 r:add('<li>Debug')
 r:add('<menu>')
 r:add([[<li onclick="SessionManager:export_session(']]..sesname..[[','dbgmain')">Export Main Data</li>]])
 r:add([[<li onclick="SessionManager:export_session(']]..sesname..[[','dbglog')">Export Log</li>]])
 r:add('</menu>')
 r:add('</li>')
 r:add('<hr/>')
 r:add([[<li style="foreground-image: url(Resources.pak#16\icon_remove.png);" onclick="SessionManager:delsession(']]..sesname..[[')">Delete</li>]])
 r:add('</menu>')
 r:add('</tr>')
end

function SessionManager:loadtab(newtab)
 local html = SyHybrid:getfile('hybrid/sesman/list.html')
 local repdir=symini.info.sessionsdir
 local r = ctk.string.list:new()
 local p = ctk.string.loop:new()
 p:load(ctk.dir.getdirlist(repdir))
 p:reverse()
 --[[
 r:add('<meta id="element">')
 r:add('<style>'..SyHybrid:getfile('hybrid/sesman/sesman.css')..'</style>')
 r:add('<link rel="stylesheet" type="text/css" href="Common.pak#listview.css">')
 r:add('<select id="action" size="1" onchange="SessionManager:actionmenuchanged()">')
 r:add('<option value="none" SELECTED>Action</OPTION>')
 r:add('<option value="delchecked">Delete All Checked</OPTION>')
 r:add('</select>&nbsp;&nbsp;<a href="#" onclick="SessionManager:checkuncheckall(1)">Check All</a>&nbsp;&nbsp;<a href="#" onclick="SessionManager:checkuncheckall(0)">Uncheck All</a>')
 r:add('<br><br>')
 r:add('<widget type="select" style="width:100%; height:90%">')
 ]]
 while p:parsing() do
  sesfile=repdir..'\\'..p.current..'\\_Main.jrm'
  if ctk.file.exists(sesfile) then
   self:add_session(r, p.current)
  end
 end
 --r:add('</widget>')
 html = ctk.string.replace(html,'%sessions%',r.text)
 if newtab == true then
  local j = {}
  j.title = 'Past Sessions'
  j.icon = 'url(PenTools.scx#images\\icon_clock.png)'
  j.table = 'SessionManager.ui'
  j.toolbar = 'SyHybrid.scx#hybrid\\sesman\\toolbar.html'
  j.html = html
  browser.newtabx(j)
 else
  tab:loadx(html)
 end
 r:release()
 p:release()
end

function SessionManager:deleteallchecked()
 local e = self.ui.element
 local repdir=symini.info.sessionsdir
 local state = false
 local resp=app.ask_yn('Are you sure you want to delete the selected sessions?',self.title)
 if resp==true then 
  local p = ctk.string.loop:new()
  p:load(ctk.dir.getdirlist(repdir))
  while p:parsing() do
   e:select('input[session="'..p.current..'"]')
   state=e.value
   if state==true then
    ctk.dir.delete(repdir..'\\'..p.current)
   end
  end
  p:release()
  self:loadtab(false)
 end
end

function SessionManager:actionmenuchanged()
 local ui = self.ui
 if ui.action.value=='delchecked' then
  self:deleteallchecked()
 end
end

function SessionManager:import_session()
 local repdir=symini.info.sessionsdir
 local srcfile = app.openfile('Syhunt Session Export file (*.sse)|*.sse','sse')
 if ctk.file.exists(srcfile) == true then
   local sesname = ctk.file.getname(srcfile)
   sesname = ctk.string.before(sesname, '.sse')
   ctk.dir.unpackfromtar(srcfile, repdir..'\\'..sesname)
   self:loadtab(false)
 end
end

function SessionManager:export_session(sesname,mode)
 local repdir=symini.info.sessionsdir
 local sugfn = 'syhunt_'..sesname
 local mode = mode or ''
 local mask = '*.*'
 if mode == 'dbgmain' then
   mask = '*.json'
   sugfn = sugfn..'_dbgmain'
 end
 if mode == 'dbglog' then
   mask = '*.log'
   sugfn = sugfn..'_dbglog'
 end 
 local destfile = app.savefile('Syhunt Session Export file (*.sse)|*.sse','sse',sugfn)
 if destfile ~= '' then
  ctk.dir.packtotar(repdir..'\\'..sesname,destfile,mask)
 end
end
 
function SessionManager:delsession(sesname)
 local repdir=symini.info.sessionsdir
 local resp=app.ask_yn("Are you sure you want to delete '"..sesname.."'?",self.title)
 if resp==true then 
  if repdir ~= '' then
   ctk.dir.delete(repdir..'\\'..sesname)
  end
  self:loadtab(false)
 end
end
