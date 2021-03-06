require "SyMini"

task.caption = 'Issues Submission Task'
local hs = symini.hybrid:new()
local itemfailed = false
local failed_count = 0
hs:start()
  
function sendissuefromfile(tracker, filename)
  local issue = {}
  issue = hs:tracker_getissuebyfilename(filename, params.app)
  issue.tracker = tracker
  print('Sending issue: '..issue.summary..'...')
  local res = hs:tracker_sendissue(issue)
  if res.alreadysent == true then
    print('Already sent!')
  end
  if res.success == false then
    itemfailed = true
    failed_count = failed_count + 1
    print('Failed! '..res.errormsg)
  end
end

print('Sending vulnerabilities to tracker: '..params.tracker..' ['..params.app..']...')
list = ctk.string.loop:new()
list:load(params.filenamelist)
while list:parsing() do
  task:setprogress(list.curindex,list.count)
  sendissuefromfile(params.tracker, list.current)
end
task:setprogress(list.curindex,list.count)

task.status = 'Done.'
if itemfailed == true then
  printfailure(task.status)
  print(tostring(failed_count)..' item(s) failed.')
else
  printsuccess(task.status)
end

list:release()
hs:release()