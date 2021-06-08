require "SyMini"

task.caption = 'Syhunt Code Task'
task.tag = params.sessionname
task:setscript('ondblclick',"browser.showbottombar('task messages')")
task:setscript('onstop',"SessionManager:setsessionstatus([["..params.sessionname.."]], 'Canceled')")
runtabcmd('seticon','@ICON_LOADING')
runtabcmd('runtbtis','MarkAsScanning();')
runtabcmd('syncwithtask','1')
if params.targettype == 'dir' then
  print('Scanning directory: '..params.codedir..'...')
end
if params.targettype == 'file' then
  print('Scanning filename: '..params.codefile..'...')
end
if params.targettype == 'url' then
  print('Scanning repository URL: '..params.codeurl)
  if params.codebranch ~= 'master' then
    print('Branch: '..params.codebranch)
  end
  if params.codetfsver ~= 'latest' then
    print('TFS Version: '..params.codetfsver)
  end  
end

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
  runtabcmd('treesetaffecteditems',cs.affectedscripts)
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

function dirscan(dir)
  local j = ctk.json.object:new()
  j.dir = dir
  local jsonstr = tostring(j)
  j:release()  
  if params.targettype ~= 'dir' then
    print('Switching to target directory:'..dir)
    runtabcmd('treeloaddir', jsonstr)
  end
end

cs = symini.code:new()
cs.debug = true
cs.ondirscan = dirscan
cs.onlogmessage = log
cs.onvulnfound = addvuln
cs.onprogressupdate = updateprogress
cs.onstatsupdate = statsupdate
cs.sessionname = params.sessionname
cs.huntmethod = params.huntmethod
if params.targettype == 'dir' then
  cs:scandir(params.codedir)
end
if params.targettype == 'file' then
  cs:scanfile(params.codefile)
end
if params.targettype == 'url' then
  cs:scanurl({
    url=params.codeurl,
    dir=params.codedir,
    branch=params.codebranch,
    tfsver=params.codetfsver
    })
end
task.status = 'Done.'

if cs.vulnstatus == 'Vulnerable' then
	print('Vulnerable.')
	if cs.vulncount == 1 then
		print('Found 1 vulnerability')
	else
		print('Found '..cs.vulncount..' vulnerabilities')
	end
	printfailure(task.status)
	runtabcmd('seticon','url(SyHybrid.scx#images\\16\\folder_red.png)')
	runtabcmd('treesetaffecteditems',cs.affectedscripts)
	runtabcmd('runtbtis','MarkAsVulnerable();')
end
if cs.vulnstatus == 'Secure' then
	print('Secure.')
	printsuccess(task.status)
	runtabcmd('seticon','url(SyHybrid.scx#images\\16\\folder_green.png)')
	runtabcmd('runtbtis','MarkAsSecure();')
end

if cs.aborted == true then
  print('Fatal Error.')
  runtabcmd('seticon','@ICON_STOP')
  if cs.vulnerable == false then
     runtabcmd('runtbtis','MarkAsUndetermined();')
  end
  printfatalerror(cs.errorreason)
end

if cs.warnings ~= '' then
  runcmd('showmsg',cs.warnings)
end

cs:release()
