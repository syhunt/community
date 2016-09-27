require "SyMini"
geodb = require "mmdb".open(getappdir().."Packs\\GeoLite2\\GeoLite2-Country.mmdb")

function addattack(t)
  local ipcountry = {}
  local j = slx.json.object:new()
  if string.match(t.ip,'[:]') then
    ipcountry = geodb:search_ipv6(t.ip)
  else
    ipcountry = geodb:search_ipv4(t.ip)
  end
  j.caption = tostring(t.line)
  j.subitemcount = 8
  j.subitem1 = t.date
  j.subitem2 = t.ip
  j.subitem3 = t.request
  j.subitem4 = tostring(t.statuscode)
  j.subitem5 = t.description
  j.subitem6 = ipcountry.country.names.en
  j.subitem7 = t.tooltitle
  j.subitem8 = t.ip
  j.imageindex = 0
  if t.statuscode == 404 then
    j.imageindex = 13
  elseif t.statuscode == 500 then
    j.imageindex = 14
  elseif t.statuscode == 503 then
    j.imageindex = 15
  end
  if t.isbreach == true then
    j.imageindex = 25
  end
  local jsonstr = tostring(j)
  j:release()
  i:logcustomalert(slx.base64.encode(jsonstr))
  runtabcmd('resaddcustomitem',jsonstr)
end

function log(s)
  print(s)
  runtabcmd('setstatus',s) -- Updates the tab status bar text
end

function updateprogress(pos,max)
	task:setprogress(pos,max)
end

task.caption = 'Syhunt Insight Task - '..slx.file.getname(params.logfile)

if params.huntmethod == 'reconstruct' then
  task.caption = task.caption..' Session Reconstruction'
end

task:setscript('ondblclick',"browser.showbottombar('taskmon')")
runtabcmd('seticon','@ICON_LOADING')
runtabcmd('runtbtis','MarkAsScanning();')
runtabcmd('syncwithtask','1')
log('Scanning log file: '..params.logfile..'...')
if params.targetip ~= '' then
  log('Reconstructing session for IP:'..params.targetip)
end

i = symini.insight:new()
i.debug = false
i.onlogmessage = log
i.onattackfound = addattack
i.onprogressupdate = updateprogress
i.resolveip = false
i.sessionname = params.sessionname
i.huntmethod = params.huntmethod
i.targetip = params.targetip or ""
i:scanfile(params.logfile)
task.status = 'Done.'

if i.attackcount ~= 0 then
	printfailure(task.status)
	if i.breached == true then
	  runtabcmd('seticon','url(Resources.pak#16\\icon_engerror.png)')
	  runtabcmd('runtbtis','MarkAsBreached();')
	  log('Warning: The web server has been breached.')
	else
	  runtabcmd('seticon','@ICON_CHECKED_RED')
	  runtabcmd('runtbtis','MarkAsAttacked();')
	  log('No sign of breach.')
	  if params.huntmethod == 'reconstruct' then
  	  log(string.format('Found %i possible attacks originating from IP: %s.',i.attackcount,params.targetip))
  	else
  	  log(string.format('Found %i possible attacks originating from %i sources.',i.attackcount,i.sourcecount))
  	end
	end
else
	log('No attacks found.')
	printsuccess(task.status)
	runtabcmd('seticon','@ICON_CHECKED')
	runtabcmd('runtbtis','MarkAsSecure();')
end

if i.warnings ~= '' then
  runcmd('showmsg',i.warnings)
end

i:release()
