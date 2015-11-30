require "SyMini"

task.caption = 'Syhunt Code Task'
task:setscript('ondblclick',"browser.showbottombar('taskmon')")
runtabcmd('seticon','@ICON_LOADING')
runtabcmd('runtbtis','MarkAsScanning();')
runtabcmd('syncwithtask','1')
print('Scanning directory: '..params.codedir..'...')

function addvuln(v)
  print(string.format('Found: %s',v.checkname))
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

cs:release()
