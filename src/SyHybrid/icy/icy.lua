SyhuntIcy = {}

function SyhuntIcy:Load()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyCode.ico'
	self:NewTab()
    app.seticonfromfile(mainico)
	browser.info.fullname = 'Syhunt Code'
	browser.info.name = 'Code'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntIcyDark'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#code/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("results");')
	PageMenu.newtabscript = 'SyhuntIcy:NewTab()'
end

function SyhuntIcy:NewReport()
    app.showmessage('This tool is coming soon!')
end

function SyhuntIcy:ViewTargets()
    app.showmessage('Coming soon.')
end