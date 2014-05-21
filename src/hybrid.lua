SyHybrid = extensionpack:new()
SyHybrid.filename = 'SyHybrid.scx'
SyHybrid.SessionManager = function() SessionManager:loadtab(true) end
SyHybrid.ViewCatSense = function() tab:loadx(catsense_analyze(tab.source,tab.url)) end

function SyHybrid:Init()
	-- Sets additional execution modes
	browser.setinitmode('syhunthybrid','SyHybrid:LoadLauncher()')
	browser.setinitmode('syhuntcode','SyhuntCode:Load()')

	-- Inserts new toolbar menu options for each mode
	local ct_html = "<li id='tnewsyhuntcodetab' style='foreground-image: url(Syhunt.scx#images\\icon_sast.png)' onclick='SyhuntCode:NewTab()'>New Code Scanner Tab</li>"
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

	-- Adds some additional credits to the about screen
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
	self:NewTab()
	app.seticonfromres('SYHUNTICON')
	browser.info.fullname = 'Syhunt Hybrid'
	browser.info.name = 'Hybrid'
	browser.info.exefilename = app.dir..'SyHybrid.exe'
	browser.info.abouturl = 'http://www.syhunt.com/?n=Syhunt.Hybrid'
end

function SyHybrid:NewTab()
	local html = SyHybrid:getfile('hybrid/launcher/launcher.html')
	local j = {}
	j.icon = 'url(Syhunt.scx#images\\icon_syhunt.png)'
	j.title = 'Welcome'
	j.toolbar = 'SyHybrid.scx#hybrid\\launcher\\toolbar.html'
	j.table = 'SyHybrid.ui'
	j.html = html
	j.showpagestrip = false
	browser.newtabx(j)
end

function SyHybrid:NewConsoleTab(mode)
	mode = mode or 'sc'
	browser.options.showconsole = true
	Sandcat:SetConsoleMode(mode)
end

function SyHybrid:NewConsoleTabEx(mode)
	mode = mode or 'sc'
	local t = {}
	t.title = 'Console'
	t.icon = 'url(Resources.pak#16\\icon_consolesimple.png)'
	t.tag = 'console'
	if browser.newtabx(t) ~= 0 then
		Sandcat:SetConsoleMode(mode)
		browser.setactivepage('console')
	end
end

function SyHybrid:VulnList()
	if VulnList == nil then
		self:dofile('hybrid/vulnlist.lua')
	end
	VulnList:loadtab()
end
