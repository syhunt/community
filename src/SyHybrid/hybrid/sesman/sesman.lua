require 'SyHybrid'

SessionManager = {
 title = 'Session Manager'
}

function getval(tag)
 return ctk.html.gettagcontents(sesdata.text,tag)
end

function SessionManager:show_sessiondetails(sesname)
 local repdir=session_getsessionsdir()
 local r = ctk.string.list:new()
 sesdata = ctk.string.list:new()
 sesfile=repdir..'\\'..sesname..'\\_Main.xrm'
 if ctk.file.exists(sesfile) then
  sesdata.text = ctk.file.getcontents(sesfile)
  r:add('<style>'..SyHybrid:getfile('hybrid/sesman/sesman.css')..'</style>')
  --r:add('<link rel="stylesheet" type="text/css" href="Common.pak#listview.css">')
  local sourcedir = getval('source_code_directory')
  local targetfile = getval('target_file')
  r:add('<fieldset><legend style="color:black">'..sesname..'</legend>')
  r:add('Date: '..getval('date')..'<br>')
  if sourcedir ~= '' then
   r:add('Target(s): '..sourcedir..'<br>')
  elseif targetfile ~= '' then
   r:add('Target(s): '..targetfile..'<br>')
  else
   r:add('Target(s): '..getval('targets')..' ('..getval('ports')..')<br>')
  end
  r:add('Hunt Method: '..getval('scan_method')..'<br>')
  r:add('Status: '..getval('status'))
  r:add('<p align="right">')
  --if sesname ~= UI.SessionName then
  --r:add([[<button onclick="SessionManager:load_session(']]..sesname..[[')">Load</button>]])
  --end
  --if getval('status') == 'Canceled' then
  -- r:add([[<button onclick="UI:ResumeSession(']]..sesname..[[')">Resume</button>]])
  --else
  -- r:add([[<button disabled>Resume</button>]])
  --end
  r:add([[<button onclick="ReportMaker:loadtab(']]..sesname..[[')">Generate Report</button>]])
  r:add([[<button onclick="SessionManager:delsession(']]..sesname..[[')">Delete</button>]])
  r:add('</p>')
  r:add('</fieldset><br>')
  r:add('Vulnerabilities:')
  r:add('<div style="width:100%%;height:100%%;">')
  r:add('<widget type="select" style="padding:0;">')
  r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
  r:add('<tr><th width="20%">Description</th><th width="15%">Location</th><th width="20%">Affected Param(s)</th><th width="10%">Line(s)</th><th width="15%">Type/Result</th><th width="10%">Risk</th></tr>')
  l = ctk.string.loop:new()
  v = ctk.string.loop:new()
  l:load(ctk.dir.getfilelist(repdir..'\\'..sesname..'\\*_Vulns.log'))
  while l:parsing() do
   v:load(ctk.file.getcontents(repdir..'\\'..sesname..'\\'..l.current))
   while v:parsing() do
    local vname=ctk.html.escape(v:curgetvalue('vname'))
    local vpath=ctk.html.escape(v:curgetvalue('vpath'))
    local vpars=ctk.html.escape(v:curgetvalue('vpars'))
    local vpath_hex = ctk.convert.strtohex(v:curgetvalue('vpath'))
    r:add('<tr role="option" ><td>'..vname..'</td><td><a href="#" onclick="browser.newtab(ctk.convert.hextostr([['..vpath_hex..']]))">'..vpath..'</a></td><td>'..vpars..'</td><td>'..v:curgetvalue('vlns')..'</td><td>'..v:curgetvalue('vstat')..'</td><td>'..v:curgetvalue('vrisk')..'</td></tr>')
   end
  end
  v:release()
  l:release()
  r:add('</table>')
  r:add('</widget>')
  r:add('</div>')
  local j = {}
  j.title = 'Session Details - '..sesname
  j.icon = 'SyHybrid.scx#images\\icon_dast.png'
  j.html = r.text
  browser.newtabx(j)
 end
 sesdata:release()
 r:release()
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
 local repdir=session_getsessionsdir()
 local boolstate = false
 if state==1 then boolstate=true end
 p = ctk.string.loop:new()
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

function SessionManager:add_session(sesname,oldformat)
 sesdata.text = ctk.file.getcontents(sesfile)
 local sesnamehex = ctk.convert.strtohex(sesname)
 local scanmethod = getval('scan_method')
 local sourcedir = getval('source_code_directory')
 local targetfile = getval('target_file')
 local icon = 'SyHybrid.scx#images/16/shield_tick.png'
 -- Support for old session file format (.hrm)
 if oldformat then
   scanmethod=getval('scan method')
 end
 
 local vcount=getval('vulnerabilities')
 if vcount == '' then vcount = '0' end
 local status=getval('status')
 if status == 'Completed' then
  if vcount ~= '0' then
    status = 'Vulnerable'
  else
    status = 'Secure'
  end
 end
 
 -- Handle the status differently if this is a log scan
 if scanmethod == 'Web Server Log Scan' then
  local atkcount = getval('attacks')
  if atkcount == '' then atkcount = '0' end
  if atkcount ~= '0' then
    status = 'Attacks Found'
  else
    status = 'No Attacks'
  end
   vcount = atkcount
 end
 
 if vcount ~= '0' then icon = 'SyHybrid.scx#images/16/shield_exclamation.png' end
 
 r:add('<tr role="option" style="context-menu: selector(#menu'..sesnamehex..');" ')
 r:add([[ondblclick="SessionManager:load_session(']]..sesname..[[')" ]])
 r:add('>')
 r:add('<td><input type="checkbox" session="'..sesname..'"><img .lvfileicon src="'..icon..'">&nbsp;'..getval('date')..' ('..sesname..')</td>')
 if sourcedir ~= '' then
  r:add('<td>'..sourcedir..'</td>')
 elseif targetfile ~= '' then
  r:add('<td>'..targetfile..'</td>')
 else
  r:add('<td>'..ctk.html.escape(getval('targets'))..self:get_ports(getval('ports'))..'</td>')
 end
 r:add('<td>'..scanmethod..'</td>')
 r:add('<td>'..status..'&nbsp;<img .lvfileicon src="'..self:getcounticon(vcount)..'"></td>')
 r:add('<menu.context id="menu'..sesnamehex..'">')
 r:add([[<li style="foreground-image: url(SyHybrid.scx#images\16\saverep.png);" onclick="ReportMaker:loadtab(']]..sesname..[[')">Generate Report</li>]])
 r:add([[<li onclick="SessionManager:show_sessiondetails(']]..sesname..[[')">View Vulnerabilities</li>]])
 r:add([[<li onclick="SessionManager:load_session(']]..sesname..[[')">Load In New Tab</li>]])
 r:add('<hr/>')
 r:add([[<li style="foreground-image: url(Resources.pak#16\icon_remove.png);" onclick="SessionManager:delsession(']]..sesname..[[')">Delete</li>]])
 r:add('</menu>')
 r:add('</tr>')
end

function SessionManager:loadtab(newtab)
 local html = SyHybrid:getfile('hybrid/sesman/list.html')
 local repdir=session_getsessionsdir()
 r = ctk.string.list:new()
 sesdata = ctk.string.list:new()
 p = ctk.string.loop:new()
 p:load(ctk.dir.getdirlist(repdir))
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
  sesfile=repdir..'\\'..p.current..'\\_Main.xrm'
  if ctk.file.exists(sesfile) then
   self:add_session(p.current)
  else
   sesfile=repdir..'\\'..p.current..'\\_Main.hrm' --old session data format
   if ctk.file.exists(sesfile) then self:add_session(p.current,true) end
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
 sesdata:release()
 p:release()
end

function SessionManager:deleteallchecked()
 local e = self.ui.element
 local repdir=session_getsessionsdir()
 local state = false
 local resp=app.ask_yn('Are you sure you want to delete the selected sessions?',self.title)
 if resp==true then 
  p = ctk.string.loop:new()
  p:load(ctk.dir.getdirlist(repdir))
  while p:parsing() do
   e:select('input[session="'..p.current..'"]')
   state=e.value
   if state==true then
    ctk.dir.delete(repdir..'\\'..p.current)
    --if UI.SessionName == p.current then UI:NewSession() end
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
 
function SessionManager:delsession(sesname)
 local repdir=session_getsessionsdir()
 local resp=app.ask_yn("Are you sure you want to delete '"..sesname.."'?",self.title)
 if resp==true then 
  if repdir ~= '' then
   ctk.dir.delete(repdir..'\\'..sesname)
   --if UI.SessionName == sesname then UI:NewSession() end
  end
  self:loadtab(false)
 end
end
