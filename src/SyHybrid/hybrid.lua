SyHybrid = extensionpack:new()
SyHybrid.filename = 'SyHybrid.scx'
SyHybrid.ViewCatSense = function() tab:loadx(catsense_analyze(tab.source,tab.url)) end

function SyHybrid:Init()
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
end

function SyHybrid:AfterInit()
	-- Loads the main Hybrid clibs
	require "SyMini"

	-- Loads the main Hybrid libraries that are included with this pack
	self:dofile('hybrid/user.lua')
	self:dofile('hybrid/repmaker/repmaker.lua')
	self:dofile('hybrid/sesman/sesman.lua')
	self:dofile('hybrid/trackman/trackman.lua')
	self:dofile('hybrid/scheduler/scheduler.lua')
	self:dofile('dynamic/dynamic.lua')
	self:dofile('dynamic/links.lua')
	self:dofile('code/code.lua')
	self:dofile('insight/insight.lua')

	-- Adds some additional credits to the about screen
	browser.addlibinfo('famfamfam flag icons','','Mark James')
	browser.addlibinfo('mmdblua library','','Daurnimator')
	browser.addlibinfo('GeoLite2 data','2','<a href="#" onclick="browser.newtab([[http://www.maxmind.com]])">MaxMind</a>')
	--browser.addlibinfo('PDF Creation library','2.0','K. Nishita')
	--browser.addlibinfo('RTF Creation library','1.0','K. Nishita')
	browser.addlibinfo('TAR Components','2.1.1','Stefan Heymann')
    --browser.addlibinfo('XML Components','1.0.17','Stefan Heymann','Sandcat:ShowLicense(SyHybrid.filename,[[hybrid\\docs\\Licence_XMLComps.txt]])')

	-- Adds new Sandcat Console commands
	SyhuntDynamic:AddCommands()

	-- Checks the current installation for user details and a valid configuration
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
    local mainexe = app.dir..'SyHybrid.dll'
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

function SyHybrid:Load()
    self:Launcher()
    self:SetHybridMode()
end

function SyHybrid:Launcher()
    local warningmsg = ''
    local stat = symini.checkrenew()
    if stat.expnear == true then
      warningmsg = [[<include src="Professional.pak#hybrid/launcher/warningrenew.html" />]]
    end
    local logos = ''
	local html = SyHybrid:getfile('hybrid/launcher/startpage.html')
    logos = logos..SyHybridUser:GetEditionLogo()
    html = ctk.string.replace(html, '<!--logoplus-->',logos)	
    html = ctk.string.replace(html, '<!--warningmsg-->',warningmsg)
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
