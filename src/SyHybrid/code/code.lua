SyhuntCode = {}

function SyhuntCode:Load()
    local mainexe = app.dir..'SyCode.exe'
	self:NewTab()
    app.seticonfromfile(mainexe)
	browser.info.fullname = 'Syhunt Code'
	browser.info.name = 'Code'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntCode'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#code/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("results");')
	PageMenu.newtabscript = 'SyhuntCode:NewTab()'
end

function SyhuntCode:LoadSession(sesname)
 debug.print('Loading Code session: '..sesname)
 if self:NewTab() ~= '' then
  tab:userdata_set('session',sesname)
  local s = symini.session:new()
  s.name = sesname
  local dir = s:getvalue('source code directory')
  if dir ~= '' then
   self:LoadTree(dir,s:getvalue('vulnerable scripts'))
  end
  if s.vulnerable then
   tab.icon = 'url(SyHybrid.scx#images\\16\\folder_red.png)'
   tab.toolbar:eval('MarkAsVulnerable();')
  else
   tab.icon = 'url(SyHybrid.scx#images\\16\\folder_green.png)'
   tab.toolbar:eval('MarkAsSecure();')
  end
  tab.title = sesname
  s:release()
 end
end

function SyhuntCode:EditPreferences()
	local slp = ctk.string.loop:new()
	local t = {}
	local cs = symini.code:new()
	slp:load(cs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,cs:prefs_getdefault(slp.current))
	end
	t.html = SyHybrid:getfile('code/prefs/prefs.html')
	t.html = ctk.string.replace(t.html,'%code_checks%',SyHybrid:GetOptionsHTML(cs.options_checks))
	t.html = ctk.string.replace(t.html,'%code_mapping_checks%',SyHybrid:GetOptionsHTML(cs.options_checksmap))
	t.id = 'syhuntcode'
	t.options = cs.options
	t.options_disabled = cs.options_locked
	Sandcat.Preferences:EditCustom(t)
	cs:release()
	slp:release()
end

function SyhuntCode:IsScanInProgress(warn)
  warn = warn or false
  local tid = tab:userdata_get('taskid','')
  if tid ~= '' then
    if browser.gettaskinfo(tid).enabled == false then
      return false
    else
      if warn == true then
        app.showmessage('A scan is in progress.')
      end
      return true
    end
  else
    return false
  end
end

function SyhuntCode:LoadProgressPanel()
    local html = SyHybrid:getfile('code/progress.html')
    tab:results_loadx(html)
end

function SyhuntCode:NewScan()
  if self:IsScanInProgress(true) == false then
	  tab:tree_clear()
	  self.ui.dir.value = ''
	  tab.source = ''
	  tab:loadsourcemsgs('')
	  tab:userdata_set('session','')
      tab:userdata_set('taskid','')
	  tab:runsrccmd('showmsgs',false)
	  tab.toolbar:eval('MarkReset();')
	  tab:results_clear()
	  self:LoadProgressPanel()
	end
end

function SyhuntCode:NewScanDialog()
  local tab = self:NewTab()
  if tab ~= '' then
     self:ScanFolder('')
  end 
end

function SyhuntCode:NewTab()
    local cr = {}
    cr.clickfunc = 'SyhuntDynamic:EditVulnDetails'
    cr.columns = SyHybrid:getfile('dynamic/vulncols.lst')
	local aliases = SyHybrid:getfile('code/aliases.lst')
	local j = {}
	if browser.info.initmode == 'syhuntcode' then
	  j.icon = 'url(PenTools.scx#images\\icon_sast.png)'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\code.png)'
	end
	j.title = 'New Tab'
	j.toolbar = 'SyHybrid.scx#code\\toolbar\\toolbar.html'
	j.table = 'SyhuntCode.ui'
	j.activepage = 'results'
	j.showpagestrip = true
	local newtab = browser.newtabx(j)
	if newtab ~= '' then
	    tab.showtree = true
		browser.setactivepage(j.activepage)
		--browser.pagebar:eval('Tabs.Select("source");')
		tab:results_customize(cr)
        self:LoadProgressPanel()
		tab:loadsourcetabs([[All,Alerts,"Key Areas",JavaScript,HTML,"Interesting Findings"]],aliases)
	end
	return newtab
end

function SyhuntCode:Search()
	PenTools:PageFind()
	SearchSource:search(self.ui.search.value)
end

function SyhuntCode.OpenFile(f)
	local file = SyhuntCode.ui.dir.value..'\\'..f
	local ext = ctk.file.getext(file)
	if ctk.file.exists(file) then
		tab.title = ctk.file.getname(f)
		local ses = symini.session:new()
		ses.name = tab:userdata_get('session')
		f = ctk.string.replace(f,'\\','/')
		tab:loadsourcemsgs(ses:getcodereview('/'..f))
		tab.logtext = ses:getcodereviewlog('/'..f)
		tab.downloadfiles = false
		tab.updatesource = false
		tab:gotourl(file)
		tab:runsrccmd('readonly',false)
		tab:runsrccmd('loadfromfile',file)
		if ctk.re.match(ext,'.bmp|.gif|.ico|.jpg|.jpeg|.png|.svg') == true then
			browser.setactivepage('browser')
		else
		    browser.setactivepage('source')
		end
		ses:release()
	end
end

function SyhuntCode:PauseScan()
  local tid = tab:userdata_get('taskid','')
  if tid ~= '' then
    browser.suspendtask(tid)
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
	local opt = {}
	opt.dir = dir..'\\'
	opt.recurse = true
	opt.makebold = true
	opt.affscripts = affscripts
	tab:tree_loaddir(opt)
	tab.title = ctk.file.getname(dir)
end

function SyhuntCode:ScanFolder(huntmethod)
  local canscan = true
  if self:IsScanInProgress(true) == true then
    canscan = false
  else
    if SyHybridUser:IsMethodAvailable(huntmethod, true) == false then
      canscan = false
    end
  end
  if canscan == true then
	  local dir = app.selectdir('Select a source code directory to scan:')
	  if dir ~= '' then
  		prefs.save()
  		self:NewScan()
  		self:LoadTree(dir,'')
  		local script = SyHybrid:getfile('code/scantask.lua')
  		local j = ctk.json.object:new()
	  	j.sessionname = symini.getsessionname()
  		tab:userdata_set('session',j.sessionname)
  		j.codedir = dir..'\\'
  		j.huntmethod = huntmethod
		  local menu = [[
		  <!--li onclick="browser.showbottombar('task messages')">View Messages</li-->
		  <li onclick="SessionManager:show_sessiondetails('%s')">View Vulnerabilities</li>
	  	<li style="foreground-image: url(SyHybrid.scx#images\16\saverep.png);" onclick="ReportMaker:loadtab('%s')">Generate Report</li>
	  	]]
	  	menu = ctk.string.replace(menu,'%s',j.sessionname)
  		local tid = tab:runtask(script,tostring(j),menu)
      tab:userdata_set('taskid',tid)
  		j:release()
  		browser.setactivepage('results')
  	end
  end
end

function SyhuntCode:ShowResults(list)
	local html =  SyHybrid:getfile('code/results.html')
	local slp = ctk.string.loop:new()
	local script = ctk.string.list:new()
	local j = ctk.json.object:new()
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

function SyhuntCode:StopScan()
  local tid = tab:userdata_get('taskid','')
  if tid ~= '' then
    browser.stoptask(tid,'User requested')
    tab.icon = '@ICON_STOP'
    tab.toolbar:eval('MarkAsStopped()')
  end
end

function SyhuntCode:ViewVulnerabilities()
  local sesname = tab:userdata_get('session','')
  if sesname ~= '' then
      SessionManager:show_sessiondetails(sesname)
  else
    app.showmessage('No session loaded.')
  end
end