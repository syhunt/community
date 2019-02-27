require "SyMini"

function updateprogress(pos,max)
	task:setprogress(pos,max)
end

function sitemapupdate(t)
  runtabcmd('settreeurls', t.urls)
  runtabcmd('setaffecteditems',hs.vulnurls)
end

function statsupdate(t)
  runtabcmd('resupdatehtml', t.csv)
end

function addvuln(v)
  local loc = v.location
  if v.locationsrc ~= '' then
    -- replace by source code location
    loc = v.locationsrc
  end
  print(string.format('Found: %s at %s',v.checkname,loc))
  local j = ctk.json.object:new()
  j.caption = v.checkname
  j.subitemcount = 5
  j.subitem1 = v.location
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
  runtabcmd('setaffecteditems',hs.vulnurls)
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
	  if hs.aborted == false then
        if params.huntmethod == 'spider' then
	      runtabcmd('seticon','@ICON_CHECKED')
          runtabcmd('runtbtis','MarkAsDone();')
	      printsuccess(task.status)
        else
          print('Secure.')
	      runtabcmd('seticon','@ICON_CHECKED')
          runtabcmd('runtbtis','MarkAsSecure();')
	      printsuccess(task.status)
        end
	  else
        print('Undetermined (scan aborted).')
	    runtabcmd('seticon','@ICON_STOP')
        runtabcmd('runtbtis','MarkAsUndetermined();')
	    printfailure(task.status)
	  end
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
task:setscript('ondblclick',"browser.showbottombar('task messages')")
task:setscript('onstop',"SessionManager:setsessionstatus([["..params.sessionname.."]], 'Canceled')")

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
hs.onmapupdate = sitemapupdate
hs.onstatsupdate = statsupdate
hs.onrequestdone = requestdone
hs:start()
hs.starturl = params.starturl
hs.urllist = params.urllist
hs.huntmethod = params.huntmethod
hs.sessionname = params.sessionname
hs:scan()
task.status = 'Done.'
printscanresult()

if hs.warnings ~= '' then
  runcmd('showmsg',hs.warnings)
end

hs:release()
