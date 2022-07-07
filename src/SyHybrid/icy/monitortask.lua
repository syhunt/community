require "SyMini"

function updateprogress(pos,max)
	task:setprogress(pos,max)
end

function log(s)
  outputmsg(s,-1) -- Adds to messages listview
  print(s)
  runtabcmd('setstatus',s) -- Updates the tab status bar text
end

task.caption = 'Syhunt Breach Checker Task'
task:setscript('ondblclick',"browser.showbottombar('task messages')")

hs = symini.breach:new()
hs.debug = true
hs.monitor = params.monitor
hs.onlogmessage = log
hs.onprogressupdate = updateprogress
--hs.ontimelimitreached = printscanresult
hs:start()
hs.huntmethod = 'darkplus'
hs:scandomains()
task.status = 'Done.'
printsuccess(task.status)

if hs.warnings ~= '' then
  runcmd('showmsg',hs.warnings)
  printfatalerror(hs.errorreason)
end

hs:release()
task:browserdostring('SyhuntIcy:ViewTargetList(true) SyhuntIcy:ViewTargetList(false)')
