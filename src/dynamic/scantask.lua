require "SyMini"

task.caption = 'Syhunt Hybrid Task'
task:setscript('ondblclick',"browser.showbottombar('taskmon')")
runtabcmd('syncwithtask','1')
print('Scanning URL: '..params.starturl..'...')
print('Hunt Method: '..params.huntmethod..'...')
print('Session Name: '..params.sessionname)

function updateprogress(pos,max)
	task:setprogress(pos,max)
end

function printscanresult()
	if hs.vulnerable == true then
		print('Vulnerable.')
		if hs.vulncount == 1 then
			print('Found 1 vulnerability')
		else
			print('Found '..hs.vulncount..' vulnerabilities')
		end
		printfailure(task.status)
	else
		print('Secure.')
		printsuccess(task.status)
	end
end

hs = symini.hybrid:new()
hs.debug = true
hs.outputmsgs = true
hs.monitor = params.monitor
hs.onprogress = 'updateprogress'
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

hs:release()
