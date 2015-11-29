SyHybrid = extensionpack:new()
SyHybrid.filename = 'SyHybrid.scx'
SyHybrid.SessionManager = function() SessionManager:loadtab(true) end
SyHybrid.ViewCatSense = function() tab:loadx(catsense_analyze(tab.source,tab.url)) end

function SyHybrid:Init()
	-- Sets additional execution modes
	browser.setinitmode('syhunthybrid','SyHybrid:LoadLauncher()')
	browser.setinitmode('syhuntcode','SyhuntCode:Load()')
	browser.setinitmode('syhuntdynamic','SyhuntDynamic:Load()')
	browser.setinitmode('syhuntinsight','SyhuntInsight:Load()')

	-- Inserts new toolbar menu options for each mode
	local ct_html = "<li id='tnewsyhuntcodetab' style='foreground-image: url(SyHybrid.scx#images\\16\\code.png)' onclick='SyhuntCode:NewTab()'>New Code Tab</li>"
	local bt_html = "<li id='tnewbrowsertab' style='foreground-image: @ICON_SANDCAT' onclick='browser.newtab()'>New Browser Tab</li>"
	if browser.info.initmode == 'syhunthybrid' then
		browser.navbar:inserthtmlfile('#pagemenu','#toolbar','SyHybrid.scx#dynamic/navbar.html')
		browser.tabbar:inserthtml("#newtab",'#tabmenuext',ct_html)
		browser.navbar:inserthtml(2,'#navbarmenu-list',ct_html)
	elseif browser.info.initmode == 'syhuntcode' then
		browser.tabbar:inserthtml("#newtab",'#tabmenuext',bt_html)
	end

	-- Adds CatSense tab
	--browser.bottombar:addtiscript('Tabs.Add("catsense","SyHybrid:ViewCatSense()")')
end

function SyHybrid:AfterInit()
	-- Loads the main Hybrid clibs
	require "SyHybrid"
	require "SyMini"

	-- Loads the main Hybrid libraries that are included with this pack
	self:dofile('hybrid/user.lua')
	self:dofile('hybrid/repmaker/repmaker.lua')
	self:dofile('hybrid/sesman/sesman.lua')
	self:dofile('dynamic/dynamic.lua')
	self:dofile('dynamic/links.lua')
	self:dofile('code/code.lua')
	self:dofile('insight/insight.lua')

	-- Adds some additional credits to the about screen
	browser.addlibinfo('famfamfam flag icons','','Mark James')
	browser.addlibinfo('mmdblua library','','Daurnimator')
	browser.addlibinfo('GeoLite2 data','2','<a href="#" onclick="browser.newtab([[http://www.maxmind.com]])">MaxMind</a>')
	browser.addlibinfo('PDF Creation library','2.0','K. Nishita')
	browser.addlibinfo('RTF Creation library','1.0','K. Nishita')
	browser.addlibinfo('TAR Components','2.1.1','Stefan Heymann')
  browser.addlibinfo('XML Components','1.0.17','Stefan Heymann','Sandcat:ShowLicense(SyHybrid.filename,[[hybrid\\docs\\Licence_XMLComps.txt]])')

	-- Adds new Sandcat Console commands
	SyhuntDynamic:AddCommands()

	-- Checks the current installation for user details and a valid configuration
	SyHybridUser:CheckInst()
end

function SyHybrid:LoadLauncher()
  local mainexe = app.dir..'SyHybrid.exe'
	self:NewTab()
	--app.seticonfromres('SYHUNTICON')
  app.seticonfromfile(mainexe)
	browser.info.fullname = 'Syhunt Hybrid'..' - ['..symini.getmodename()..']'
	browser.info.name = 'Hybrid'..' - ['..symini.getmodename()..']'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntHybrid'
end

function SyHybrid:NewTab()
	local html = SyHybrid:getfile('hybrid/launcher/launcher.html')
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
