require "SyMini"

task.caption = 'Syhunt Code Task'
task:setscript('ondblclick',"browser.showbottombar('task messages')")
runtabcmd('seticon','@ICON_LOADING')
runtabcmd('runtbtis','MarkAsScanning();')
runtabcmd('syncwithtask','1')
print('Scanning directory: '..params.codedir..'...')

function addvuln(v)
  print(string.format('Found: %s',v.checkname))
 local j = ctk.json.object:new()
  j.caption = v.checkname
  j.subitemcount = 5
  j.subitem1 = v.locationsrc
  j.subitem2 = v.params
  j.subitem3 = v.lines
  j.subitem4 = v.risk
  j.subitem5 = v.filename
  j.imageindex = 0
  local risk = string.lower(v.risk)
  if risk == 'high' then
    j.imageindex = 21
  elseif risk == 'medium' then
    j.imageindex = 22
  elseif risk == 'low' then
    j.imageindex = 23
  elseif risk == 'info' then
    j.imageindex = 24
  end
  local jsonstr = tostring(j)
  j:release()
  --hs:logcustomalert(ctk.base64.encode(jsonstr))
  runtabcmd('resaddcustomitem', jsonstr)
  runtabcmd('setaffecteditems',cs.affectedscripts)
end

function statsupdate(t)
  runtabcmd('resupdatehtml', t.csv)
end

function log(s)
  outputmsg(s,-1) -- Adds to messages listview
  runtabcmd('setstatus',s) -- Updates the tab status bar text
end

function updateprogress(pos,max)
	task:setprogress(pos,max)
end

cs = symini.code:new()
cs.debug = true
cs.onlogmessage = log
cs.onvulnfound = addvuln
cs.onprogressupdate = updateprogress
cs.onstatsupdate = statsupdate
cs.sessionname = params.sessionname
cs.huntmethod = params.huntmethod
cs:scandir(params.codedir)
task.status = 'Done.'

if cs.vulnerable == true then
	print('Vulnerable.')
	if cs.vulncount == 1 then
		print('Found 1 vulnerability')
	else
		print('Found '..cs.vulncount..' vulnerabilities')
	end
	printfailure(task.status)
	runtabcmd('seticon','url(SyHybrid.scx#images\\16\\folder_red.png)')
	runtabcmd('setaffecteditems',cs.affectedscripts)
	runtabcmd('runtbtis','MarkAsVulnerable();')
else
	print('Secure.')
	printsuccess(task.status)
	runtabcmd('seticon','url(SyHybrid.scx#images\\16\\folder_green.png)')
	runtabcmd('runtbtis','MarkAsSecure();')
end

if cs.warnings ~= '' then
  runcmd('showmsg',cs.warnings)
end

cs:release()
