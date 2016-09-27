require "SyMini"

function updateprogress(pos,max)
	task:setprogress(pos,max)
end

function addvuln(v)
  local loc = v.location
  if v.locationsrc ~= '' then
    -- replace by source code location
    loc = v.locationsrc
  end
  print(string.format('Found: %s at %s',v.checkname,loc))
  local j = slx.json.object:new()
  j.caption = v.checkname
  j.subitemcount = 6
  j.subitem1 = v.location
  j.subitem2 = v.params
  j.subitem3 = v.lines
  j.subitem4 = tostring(v.statuscode)
  j.subitem5 = v.risk
  j.subitem6 = v.location --v.filename
  j.imageindex = 0
  local risk = string.lower(v.risk)
  if risk == 'high' then
    j.imageindex = 21
  elseif risk == 'medium' then
    j.imageindex = 22
  elseif risk == 'low' then
    j.imageindex = 23
  end
  local jsonstr = tostring(j)
  j:release()
  --hs:logcustomalert(slx.base64.encode(jsonstr))
  runtabcmd('resaddcustomitem',jsonstr)
end

function log(s)
  outputmsg(s,-1) -- Adds to messages listview
  runtabcmd('setstatus',s) -- Updates the tab status bar text
end

function printscanresult()
	if hs.vulnerable == true then
		print('Vulnerable.')
		if hs.vulncount == 1 then
			print('Found 1 vulnerability')
		else
			print('Found '..hs.vulncount..' vulnerabilities')
		end
	  runtabcmd('seticon','@ICON_CHECKED_RED')
    runtabcmd('runtbtis','MarkAsVulnerable();')
		printfailure(task.status)
	else
		print('Secure.')
	  runtabcmd('seticon','@ICON_CHECKED')
    runtabcmd('runtbtis','MarkAsSecure();')
		printsuccess(task.status)
	end
end

function requestdone(r)
  -- add requests during spidering stage
  if r.isseccheck == false then
    local s = r.method..' '..r.url
    if r.postdata ~= '' then
      s = s..' ['..r.postdata..' ]'
    end
    outputmsg(s,11) -- Adds to messages listview
  end
end

task.caption = 'Syhunt Hybrid Task'
task:setscript('ondblclick',"browser.showbottombar('taskmon')")

-- if running in background mode, all runtabcmds will be ignored
if parambool('runinbg',true) == true then
  print('Running scan task in background...')
  runtabcmd = function(cmd,value) end
end

runtabcmd('seticon','@ICON_LOADING')
runtabcmd('runtbtis','MarkAsScanning();')
runtabcmd('syncwithtask','1')

print('Scanning URL: '..params.starturl..'...')
print('Hunt Method: '..params.huntmethod..'...')
print('Session Name: '..params.sessionname)

hs = symini.hybrid:new()
hs.debug = true
hs.monitor = params.monitor
hs.onlogmessage = log
hs.onvulnfound = addvuln
hs.onprogressupdate = updateprogress
hs.onrequestdone = requestdone
hs:start()
hs.starturl = params.starturl
hs.urllist = params.urllist
hs.huntmethod = params.huntmethod
hs.sessionname = params.sessionname
hs:scan()
task.status = 'Done.'

if params.huntmethod == 'spider' then
	printsuccess(task.status)
else
	printscanresult()
end

if hs.warnings ~= '' then
  runcmd('showmsg',hs.warnings)
end

hs:release()
