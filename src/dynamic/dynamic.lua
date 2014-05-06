SyhuntDynamic = {}

function SyhuntDynamic:AddCommands()
	console.addcmd('appscan',"SyhuntDynamic:ScanThisSite('appscan')",'Scans the current site')
	console.addcmd('spider',"SyhuntDynamic:ScanThisSite('spider')",'Spiders the current site')
end

function SyhuntDynamic:ScanThisSite(method)
	if Sandcat:IsURLLoaded(true) then
		self:ScanSite(tab.url,method)
	end
end

function SyhuntDynamic:ScanSite(url,method)
	method = method or 'spider'
	if url ~= '' then
		prefs.save()
		tab.captureurls = false
		local script = SyHybrid:getfile('dynamic/scantask.lua')
		local j = scl.json:new()
		j.sessionname = symini.getsessionname()
		j.huntmethod = method
		j.monitor = tab.handle
		j.urllist = tab.urllist
		j.starturl = url
		local menu = [[
		<li onclick="browser.showbottombar('taskmon')">View Messages</li>
		<li onclick="SessionManager:show_sessiondetails('%s')">View Vulnerabilities</li>
		<li style="foreground-image: url(SyHybrid.scx#images\16\spider.png);" onclick="SpiderLinks:showsessionlinks('%s')">View Links</li>
		<li style="foreground-image: url(SyHybrid.scx#images\16\saverep.png);" onclick="ReportMaker:loadtab('%s')">Generate Report</li>
		]]
		menu = stringop.replace(menu,'%s',j.sessionname)
		if symini.checkinst() then
			tab:runtask(script,tostring(j),menu)
		else
			app.showmessage('Unable to run (no Pen-Tester Key found).')
		end
		j:release()
	end
end

function SyhuntDynamic:CaptureURLs()
	if Sandcat:IsURLLoaded(true) then
		tab.captureurls = true
		app.showmessage('URL Logger enabled.')
	end
end

function SyhuntDynamic:EditPreferences(dialoghtml)
	dialoghtml = dialoghtml or 'dynamic/prefs/prefs.html'
	local slp = scl.listparser:new()
	Sandcat:dofile('dialog_prefs.lua')
	local ds = symini.dynamic:new()
	ds:start()
	slp:load(ds.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,ds:prefs_getdefault(slp.current))
	end
	Preferences:EditCustom(SyHybrid.filename,dialoghtml,'syhuntdynamic',ds.options)
	ds:release()
	slp:release()
end

function SyhuntDynamic:EditNetworkPreferences()
	self:EditPreferences('dynamic/prefs_net/prefs.html')
end

function SyhuntDynamic:EditSitePreferences()
	if stringop.beginswith(tab.url,'http') then
		local jsonfile = tab.siteprefsfilename
		local slp = scl.listparser:new()
		Sandcat:dofile('dialog_prefs.lua')
		local hs = symini.hybrid:new()
		hs:start()
		slp:load(hs.options)
		while slp:parsing() do
			prefs.regdefault(slp.current,hs:prefs_getdefault(slp.current))
		end
		Preferences:EditCustomFile(SyHybrid.filename,'dynamic/prefs_site/prefs.html','syhuntsiteprefs',hs.options,jsonfile)
		hs:release()
		slp:release()
	else
		app.showmessage('No site loaded.')
	end
end

function SyhuntDynamic:NewTab()
	browser.newtab()
end
