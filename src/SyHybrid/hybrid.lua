SyHybrid = extensionpack:new()
SyHybrid.filename = 'SyHybrid.scx'
SyHybrid.ViewCatSense = function() tab:loadx(catsense_analyze(tab.source,tab.url)) end

function SyHybrid:Init()
	-- Loads the main Hybrid clibs
	require "SyMini"
	-- Sets additional execution modes
	browser.setinitmode('syhunthybrid','SyHybrid:Load()')
	browser.setinitmode('syhuntcode','SyhuntCode:Load()')
	browser.setinitmode('syhuntdynamic','SyhuntDynamic:Load()')
	browser.setinitmode('syhuntinsight','SyhuntInsight:Load()')
	browser.setinitmode('syhuntsesman','SyHybrid:SessionManager()')

	-- Inserts new toolbar menu options for each mode
	local ct_html = [[
	<li id='tnewsyhuntcodetab' style='foreground-image: url(SyHybrid.scx#images\16\code.png)' onclick='SyhuntCode:NewTab()'>New Code Tab</li>
	<li id='tnewdynamictab' style='foreground-image: url(SyHybrid.scx#images\16\dynamic.png)' onclick='SyhuntDynamic:NewTab()'>New Dynamic Tab</li>
	<li id='tlaunchertab' style='foreground-image: url(SyHybrid.scx#images\16\launcher.png)' onclick='SyHybrid:Launcher()'>Launcher</li>
	]]
	local bt_html = "<li id='tnewbrowsertab' style='foreground-image: @ICON_SANDCAT' onclick='browser.newtab()'>New Browser Tab</li>"
	if browser.info.initmode == 'syhunthybrid' then
		browser.navbar:inserthtmlfile('#pagemenu','#toolbar','SyHybrid.scx#dynamic/navbar.html')
		browser.tabbar:inserthtml("#newtab",'#tabmenuext',ct_html)
		browser.navbar:inserthtml(2,'#navbarmenu-list',ct_html)
	elseif browser.info.initmode == 'syhuntcode' then
		browser.tabbar:inserthtml("#newtab",'#tabmenuext',bt_html)
	end
	
	-- Change browser to pen test mode
	-- Disable XSS protection
	prefs.set('sandcat.browser.security.xssauditor.enabled', false)
	prefs.save()

	-- Adds CatSense tab
	--browser.bottombar:addtiscript('Tabs.Add("catsense","SyHybrid:ViewCatSense()")')
	-- Checks the current installation for user details and a valid configuration
end

function SyHybrid:AfterInit()
	-- Loads the main Hybrid libraries that are included with this pack
	self:dofile('hybrid/user.lua')
	self:dofile('hybrid/repmaker/repmaker.lua')
	self:dofile('hybrid/sesman/sesman.lua')
	self:dofile('hybrid/trackman/trackman.lua')
	self:dofile('hybrid/scheduler/scheduler.lua')
	self:dofile('dynamic/dynamic.lua')
	self:dofile('dynamic/links.lua')
	self:dofile('code/code.lua')
	self:dofile('icy/icy.lua')	
	self:dofile('insight/insight.lua')

	-- Adds some additional credits to the about screen
	browser.addlibinfo('7-Zip','file:7z.dll','<a href="#" onclick="browser.newtab([[https://www.7-zip.org/license.txt]])">Igor Pavlov and others</a>')
	browser.addlibinfo('famfamfam flag icons','','Mark James')
	--browser.addlibinfo('mmdblua library','','Daurnimator')
	browser.addlibinfo('IP2Location LITE data','','<a href="#" onclick="browser.newtab([[http://www.ip2location.com]])">IP2Location</a>')
	--browser.addlibinfo('GeoLite2 data','2','<a href="#" onclick="browser.newtab([[http://www.maxmind.com]])">MaxMind</a>')
	--browser.addlibinfo('PDF Creation library','2.0','K. Nishita')
	--browser.addlibinfo('RTF Creation library','1.0','K. Nishita')
	browser.addlibinfo('TAR Components','2.1.1','Stefan Heymann')
	browser.addlibinfo('TFS Tools','15.18.1215.60','<a href="#" onclick="browser.newtab([[https://blogs.msmvps.com/vstsblog/tfs2018-tools/]])">Neno Loje</a>')
    --browser.addlibinfo('XML Components','1.0.17','Stefan Heymann','Sandcat:ShowLicense(SyHybrid.filename,[[hybrid\\docs\\Licence_XMLComps.txt]])')

	-- Adds new Sandcat Console commands
	SyhuntDynamic:AddCommands()
	SyhuntDynamic:AddClipmon()

	SyHybridUser:CheckInst()	
end

function SyHybrid:GetOptionsHTML(options)
    local html_opt = [[<tr role="option"><td>%s<input type="checkbox" cid="%s">%s</td><td></td></tr>]]
    --local html_opt = [[<tr role="option"><td>%s<input type="checkbox" cid="%s">%s</td><td><a href="#" onclick="prefs.editlist('syhunt.dynamic.lists.extensions.bkp','Backup Extensions','Example: .bak')">Edit</a></td></tr>]]
	local slp = ctk.string.loop:new()
	local html = ctk.string.list:new()
	local opt = {}
	local level = ''
	html:add([[<tr><th style="width:*;">Check Name</th><th style="width:70px;"></th></tr>]])
	slp:load(options)
	while slp:parsing() do
		opt = symini.getoptdetails(slp.current)
		if opt.level == 1 then
		   level = '&nbsp;&nbsp;&nbsp;&nbsp;'
		else
		   level = ''
		   opt.caption = '<b>'..opt.caption..'</b>'
		end
		html:add(string.format(html_opt,level,slp.current,opt.caption))
	end
	local res = html.text
	html:release()
	slp:release()
	return res
end

function SyHybrid:SetHybridMode()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyHybrid.ico'
    if symini.info.modename == 'Community Edition' then
      mainico = app.dir..'\\Packs\\Icons\\SyCommunity.ico'
    end
    --app.seticonfromres('SYHUNTICON')
    app.seticonfromfile(mainico)
    browser.info.fullname = 'Syhunt Hybrid'..' - ['..symini.info.modename..']'
    browser.info.name = 'Hybrid'..' - ['..symini.info.modename..']'
    browser.info.exefilename = mainexe
    browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntHybrid'
end

function SyHybrid:SessionManager()
    if browser.info.initmode == 'syhuntsesman' then
      self:SetHybridMode()
    end
    SessionManager:loadtab(true)
end

function SyHybrid:ImportPreferences()
  if Sandcat.Preferences:LoadFromFile() == true then
    symini.scheduler_sendsignal('stop')
    symini.scheduler_sendsignal('start')
  end
end

function SyHybrid:EditPreferencesAI()
  html = SyHybrid:getfile('hybrid/prefs/prefs_ai.html')
  if SyHybridUser:IsOptionAvailable(true) == true then
    self:EditPreferences(html)
  end
end

function SyHybrid:EditPreferences(html)
	html = html or SyHybrid:getfile('hybrid/prefs/prefs.html')
	local slp = ctk.string.loop:new()
	local t = {}
	local rm = symini.repmaker:new()
	local hs = symini.hybrid:new()
	hs:start()
	slp:load(hs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,hs:prefs_getdefault(slp.current))
	end
	t.html = html
	t.html = ctk.string.replace(t.html,'%report_formats%',rm.filter_menu)
	t.id = 'syhuntrepmaker'
	t.options = hs.options
	t.options_disabled = hs.options_locked
	local res = Sandcat.Preferences:EditCustom(t)
	hs:release()
	slp:release()
	rm:release()
	return res
end

function SyHybrid:Load()
    self:Launcher()
    self:SetHybridMode()
end

function SyHybrid:Launcher()
    local warningmsg = ''
    local updatemsg = ''
    local stat = SyHybridUser.inststat
    if stat.expnear == true then
      warningmsg = [[<include src="Professional.pak#hybrid/launcher/warningrenew.html" />]]
    end
    if stat.veruptodate == false then
      updatemsg = SyHybrid:getfile('hybrid/launcher/updatenote.html')
      updatemsg = ctk.string.replace(updatemsg, '<!--msg-->', stat.verstatus)
    end    
    local logos = ''
	local html = SyHybrid:getfile('hybrid/launcher/startpage.html')
    logos = logos..SyHybridUser:GetEditionLogo()
    html = ctk.string.replace(html, '<!--logoplus-->',logos)	
    html = ctk.string.replace(html, '<!--warningmsg-->',warningmsg)
    html = ctk.string.replace(html, '<!--updatemsg-->',updatemsg)
	local j = {}
	j.icon = 'url(SyHybrid.scx#images\\16\\launcher.png)'
	j.title = 'Launcher'
	j.toolbar = 'SyHybrid.scx#hybrid\\launcher\\toolbar.html'
	j.table = 'SyHybrid.ui'
	j.html = html
	j.tag = 'syhuntlauncher'
	j.showpagestrip = false
	browser.newtabx(j)
end

function SyHybrid:ShowConsole(mode)
	mode = mode or 'sc'
	browser.options.showconsole = true
	console.setmode(mode)
end

function SyHybrid:VulnList()
	if VulnList == nil then
		self:dofile('hybrid/vulnlist.lua')
	end
	VulnList:loadtab()
end
