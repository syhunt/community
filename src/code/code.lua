SyhuntCode = {}

function SyhuntCode:Load()
	self.NewTab()
	app.seticonfromres('SYHUNTICON')
	browser.info.fullname = 'Syhunt Code'
	browser.info.name = 'Code'
	browser.info.exefilename = app.dir..'SyCode.exe'
	browser.info.abouturl = 'http://www.syhunt.com/?n=Syhunt.Code'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#code/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("source");')
	PageMenu.newtabscript = 'SyhuntCode:NewTab()'
end

function SyhuntCode:EditPreferences()
	local slp = slx.string.loop:new()
	Sandcat:dofile('dialog_prefs.lua')
	local cs = symini.code:new()
	slp:load(cs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,cs:prefs_getdefault(slp.current))
	end
	Preferences:EditCustom(SyHybrid.filename,'code/prefs/prefs.html','syhuntcode',cs.options)
	cs:release()
	slp:release()
end

function SyhuntCode:NewScan()
	tab:tree_clear()
	SyhuntCode.ui.dir.value = ''
	tab.source = ''
	tab:loadsourcemsgs('')
	tab:userdata_set('session','')
	tab:runsrccmd('showmsgs',false)
	tab.toolbar:eval('MarkReset();')
end

function SyhuntCode:NewTab()
	local aliases =
[[
Alert=Alerts
Key Area=Key Areas
Interesting=Interesting Findings
]]
	local j = {}
	j.icon = 'url(Syhunt.scx#images\\icon_sast.png)'
	j.title = 'New Tab'
	j.toolbar = 'SyHybrid.scx#code\\toolbar\\toolbar.html'
	j.table = 'SyhuntCode.ui'
	j.activepage = 'source'
	j.showpagestrip = true
	if browser.newtabx(j) ~= '' then
		browser.setactivepage('source')
		--browser.pagebar:eval('Tabs.Select("source");')
		tab:loadsourcetabs([[All,Alerts,"Key Areas",JavaScript,HTML,"Interesting Findings"]],aliases)
	end
end

function SyhuntCode:Search()
	Syhunt:PageFind()
	SearchSource:search(self.ui.search.value)
end

function SyhuntCode.OpenFile(f)
	local file = SyhuntCode.ui.dir.value..'\\'..f
	local ext = slx.file.getext(file)
	if slx.file.exists(file) then
		tab.title = slx.file.getname(f)
		local ses = symini.session:new()
		ses.name = tab:userdata_get('session')
		f = slx.string.replace(f,'\\','/')
		tab:loadsourcemsgs(ses:getcodereview('/'..f))
		tab.logtext = ses:getcodereviewlog('/'..f)
		tab.downloadfiles = false
		tab.updatesource = false
		tab:gotourl(file)
		tab:runsrccmd('readonly',false)
		tab:runsrccmd('loadfromfile',file)
		if slx.re.match(ext,'.bmp|.gif|.ico|.jpg|.jpeg|.png|.svg') == true then
			browser.setactivepage('browser')
		end
		ses:release()
	end
end

function SyhuntCode:SaveFile()
	if tab.sourcefilename ~= '' then
		tab:runsrccmd('savetofile',tab.sourcefilename)
	end
end

function SyhuntCode:ScanFile(f)
	if f ~= '' then
		tab.status = 'Scanning '..f..'..'
		local cs = symini.code:new()
		cs.debug = true
		cs:scanfile(f,tab.source)
		tab.status = 'Done.'
		if cs.results == '' then
			app.showmessage('No vulnerabilities or relevant findings.')
		else
			tab:loadsourcemsgs(cs.results)
		end
		tab.logtext = cs.parselog
		cs:release()
	end
end

function SyhuntCode:LoadTree(dir,affscripts)
	SyhuntCode.ui.dir.value = dir
	tab.showtree = true
	tab.tree_loaditem = SyhuntCode.OpenFile
	tab:tree_clear()
	tab:tree_loaddir(dir..'\\',true,affscripts)
	tab.title = slx.file.getname(dir)
end

function SyhuntCode:ScanFolder(huntmethod)
	local dir = app.selectdir('Select a code directory to scan:')
	if dir ~= '' then
		prefs.save()
		self:LoadTree(dir,'')
		local script = SyHybrid:getfile('code/scantask.lua')
		local j = slx.json.object:new()
		j.sessionname = symini.getsessionname()
		tab:userdata_set('session',j.sessionname)
		j.codedir = dir..'\\'
		j.huntmethod = huntmethod
		tab:runtask(script,tostring(j))
		j:release()
		browser.setactivepage('source')
	end
end

function SyhuntCode:ShowResults(list)
	local html =  SyHybrid:getfile('code/results.html')
	local slp = slx.string.loop:new()
	local script = slx.string.list:new()
	local j = slx.json.object:new()
	slp.iscsv = true
	slp:load(list)
	while slp:parsing() do
		j.line = slp:curgetvalue('l')
		j.desc = slp:curgetvalue('c')
		j.risk = slp:curgetvalue('r')
		j.type = slp:curgetvalue('t')
		script:add('AddItem('..j:getjson_unquoted()..');')
	end
	browser.options.showheaders = true
	tab.liveheaders:loadx(html)
	tab.liveheaders:eval(script.text)
	j:release()
	script:release()
	slp:release()
end
