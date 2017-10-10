require 'SyHybrid'

SessionManager = {
 title = 'Session Manager'
}

function SessionManager:show_sessiondetails(sesname)
 local details = symini.getsessiondetails(sesname)
 local sesdir = symini.info.sessionsdir
 local r = ctk.string.list:new()
  r:add('<style>'..SyHybrid:getfile('hybrid/sesman/sesman.css')..'</style>')
  r:add('<fieldset><legend style="color:black">'..sesname..'</legend>')
  r:add('Date: '..details.datetime..'<br>')
  if details.sourcedir ~= '' then
   r:add('Target(s): '..details.sourcedir..'<br>')
  elseif details.targetfile ~= '' then
   r:add('Target(s): '..details.targetfile..'<br>')
  else
   r:add('Target(s): '..details.targets..' ('..details.ports..')<br>')
  end
  r:add('Hunt Method: '..details.huntmethod..'<br>')
  r:add('Status: '..details.resultsdesc)
  r:add('<p align="right">')
  r:add([[<button onclick="ReportMaker:loadtab(']]..sesname..[[')">Generate Report</button>]])
  r:add([[<button onclick="SessionManager:delsession(']]..sesname..[[')">Delete</button>]])
  r:add('</p>')
  r:add('</fieldset><br>')
  r:add('Vulnerabilities:')
  r:add('<div style="width:100%%;height:100%%;">')
  r:add('<widget type="select" style="padding:0;">')
  r:add('<table name="reportview" width="100%" cellspacing=-1px fixedrows=1>')
  r:add('<tr><th width="20%">Description</th><th width="30%">Location</th><th width="20%">Affected Param(s)</th><th width="10%">Line(s)</th><th width="10%">Risk</th></tr>')
  l = ctk.string.loop:new()
  v = ctk.string.loop:new()
  l:load(ctk.dir.getfilelist(sesdir..'\\'..sesname..'\\*_Vulns.log'))
  while l:parsing() do
   v:load(ctk.file.getcontents(sesdir..'\\'..sesname..'\\'..l.current))
   while v:parsing() do
    local vname=ctk.html.escape(v:curgetvalue('vname'))
    local vpath=ctk.html.escape(v:curgetvalue('vpath'))
    local vpars=ctk.html.escape(v:curgetvalue('vpars'))
    local vpath_hex = ctk.convert.strtohex(v:curgetvalue('vpath'))
    r:add('<tr role="option" ><td>'..vname..'</td><td><a href="#" onclick="browser.showurl(ctk.convert.hextostr([['..vpath_hex..']]))">'..vpath..'</a></td><td>'..vpars..'</td><td>'..v:curgetvalue('vlns')..'</td><td>'..v:curgetvalue('vrisk')..'</td></tr>')
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
 local repdir=symini.info.sessionsdir
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

function SessionManager:add_session(sesname)
 local details = symini.getsessiondetails(sesname)
 local sesnamehex = ctk.convert.strtohex(sesname)
 local icon = 'SyHybrid.scx#images/16/shield_tick.png'
 local vcount = details.vulncount
 -- Handle the count differently if this is a log scan
 if details.huntmethod == 'Web Server Log Scan' then
   vcount = details.attackcount
 end
 if vcount ~= '0' then icon = 'SyHybrid.scx#images/16/shield_exclamation.png' end
 
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
 r:add('<td>'..details.resultsdesc..'&nbsp;<img .lvfileicon src="'..self:getcounticon(vcount)..'"></td>')
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
 local repdir=symini.info.sessionsdir
 r = ctk.string.list:new()
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
  sesfile=repdir..'\\'..p.current..'\\_Main.jrm'
  if ctk.file.exists(sesfile) then
   self:add_session(p.current)
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
 local repdir=symini.info.sessionsdir
 local resp=app.ask_yn("Are you sure you want to delete '"..sesname.."'?",self.title)
 if resp==true then 
  if repdir ~= '' then
   ctk.dir.delete(repdir..'\\'..sesname)
   --if UI.SessionName == sesname then UI:NewSession() end
  end
  self:loadtab(false)
 end
end
