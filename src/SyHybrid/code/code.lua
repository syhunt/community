SyhuntCode = {}

function SyhuntCode:Load()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyCode.ico'
	self:NewTab()
    app.seticonfromfile(mainico)
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
   tab:userdata_set('dir',dir)
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

function SyhuntCode:GetTargetListHTML()
  local histfile = browser.info.configdir..'Target Repositories'..'.sclist'
  local html = ''
  if ctk.file.exists(histfile) == true then
    local slp = ctk.string.loop:new()
    slp:loadfromfile(histfile)
     while slp:parsing() do
       local url = ctk.string.after(slp.current, 'url="')
       url = ctk.string.before(url,'"')
       html = html..'<li class="urlgitsetter" targeturl="'..url..'">'..url..'</li>'
     end
    slp:release()
  end
  return html
end

function SyhuntCode:EditPreferences(html)
	html = html or SyHybrid:getfile('code/prefs/prefs.html')
	local slp = ctk.string.loop:new()
	local t = {}
	local cs = symini.code:new()
	slp:load(cs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,cs:prefs_getdefault(slp.current))
	end
	t.html = html
	t.html = ctk.string.replace(t.html,'%code_checks%',SyHybrid:GetOptionsHTML(cs.options_checks))
	t.html = ctk.string.replace(t.html,'%code_mapping_checks%',SyHybrid:GetOptionsHTML(cs.options_checksmap))
	t.id = 'syhuntcode'
	t.options = cs.options
	t.options_disabled = cs.options_locked
	local res = Sandcat.Preferences:EditCustom(t)
	cs:release()
	slp:release()
	return res
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
    local k = SyHybridUser.ptkdetails
    local logos = ''
    local html = SyHybrid:getfile('code/progress.html')
    if k.lang_web == true then
      logos = logos..'<img src="SyHybrid.scx#images\\misc\\syhunt-logo-web.png">'
    end
    if k.lang_mobile == true then
      logos = logos..'<img src="SyHybrid.scx#images\\misc\\syhunt-logo-mobile.png">'
    end
    logos = logos..SyHybridUser:GetEditionLogo()
    html = ctk.string.replace(html, '<!--logoplus-->',logos)
    tab:results_loadx(html)
end

function SyhuntCode:ClearResults()
  if self:IsScanInProgress(true) == false then
      local ui = self.ui
      ui.dir.value = ''
	  tab:tree_clear()
	  tab.source = ''
	  tab:loadsourcemsgs('')
	  tab:userdata_set('dir','')
	  tab:userdata_set('session','')
      tab:userdata_set('taskid','')
	  tab:runsrccmd('showmsgs',false)
	  tab.toolbar:eval('MarkReset();')
	  tab:results_clear()
	  self:LoadProgressPanel()
	end
end

function SyhuntCode:NewScan()
  local canscan = true
  if runinbg == false then
    if self:IsScanInProgress(true) == true then
      canscan = false
    end
  end
  if canscan == true then
    self:ClearResults()
    local html = SyHybrid:getfile('code/prefs_scan/prefs.html')
    html = ctk.string.replace(html,'%code_targets%',self:GetTargetListHTML())
    local ok = self:EditPreferences(html)
    if ok == true then
      local target = {}
      target.type = prefs.get('syhunt.code.options.target.type','dir')
      if target.type == 'url' then
        target.url = prefs.get('syhunt.code.options.target.url','')
        target.branch = prefs.get('syhunt.code.options.target.branch','master')
        target.tfsver = prefs.get('syhunt.code.options.target.tfsver','latest')
      end
      if target.type == 'dir' then
        target.dir = prefs.get('syhunt.code.options.target.dir','')
      end
      if target.type == 'file' then
        target.file = prefs.get('syhunt.code.options.target.file','')
      end      
      local huntmethod = prefs.get('syhunt.code.options.huntmethod','normal')
        if ok == true then
          self:ScanTarget(huntmethod, target)
        end
    end
  end
end

function SyhuntCode:NewScanDialog()
  local tab = self:NewTab()
  if tab ~= '' then
     self:NewScan()
  end 
end

function SyhuntCode:NewTab()
    local cr = {}
    cr.dblclickfunc = 'SyhuntDynamic:EditVulnDetails'
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

function SyhuntCode:OpenFile(f)
	local file = tab:userdata_get('dir','')..'\\'..f
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
	tab.showtree = true
	tab.tree_loaditemfunc = 'SyhuntCode:OpenFile'
	tab:tree_clear()
	local opt = {}
	opt.dir = dir..'\\'
	opt.recurse = true
	opt.makebold = true
	opt.affscripts = affscripts
	tab:tree_loaddir(opt)
	tab.title = ctk.file.getname(dir)
end

function SyhuntCode:ScanFolder(huntmethod, dir)
  dir = dir or app.selectdir('Select a source code directory to scan:')
  if dir ~= '' then
    local target = {}
    target.type = 'dir'
    target.dir = dir
    self:ScanTarget(huntmethod, target)
  end
end

function SyhuntCode:SetCodeDirectory(dir)
  local ui = self.ui
  if dir ~= '' then
    tab:userdata_set('dir',dir)  	
    ui.dir.value = dir
    self:LoadTree(dir,'')
  end
end

function SyhuntCode:ScanTarget(huntmethod, target)
  huntmethod = huntmethod or 'normal'
  target.dir = target.dir or symini.getsessioncodedir()
  target.url = target.url or ''
  target.file = target.file or ''
  if target.file ~= '' then
    target.dir = ctk.file.getdir(target.file)
  end
  target.branch = target.branch or 'master'
  target.tfsver = target.tfsver or 'latest'
  local canscan = true
  if self:IsScanInProgress(true) == true then
    canscan = false
  else
    if SyHybridUser:IsMethodAvailable(huntmethod, true) == false then
      canscan = false
    end
  end
  if canscan == true then
	  if target ~= nil then
  		prefs.save()
  		self:SetCodeDirectory(target.dir)
  		local tid = 0
  		local script = SyHybrid:getfile('code/scantask.lua')
  		local j = ctk.json.object:new()
	  	j.sessionname = symini.getsessionname()
  		tab:userdata_set('session',j.sessionname)
  		j.targettype = target.type
  		j.codedir = target.dir..'\\'
  		j.codeurl = target.url
  		j.codefile = target.file
  		j.codebranch = target.branch
  		j.codetfsver = target.tfsver
  		j.huntmethod = huntmethod
		  local menu = [[
		  <!--li onclick="browser.showbottombar('task messages')">View Messages</li-->
		  <li onclick="SessionManager:show_sessiondetails('%s')">View Vulnerabilities</li>
	  	<li style="foreground-image: url(SyHybrid.scx#images\16\saverep.png);" onclick="ReportMaker:loadtab('%s')">Generate Report</li>
	  	]]
	  	menu = ctk.string.replace(menu,'%s',j.sessionname)
	  	local stat = symini.checkinst()
	  	if stat.result == true then
  		    tid = tab:runtask(script,tostring(j),menu)
		else
			app.showmessage(stat.resultstr)
		end
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
  local sesname = tab:userdata_get('session','')  
  if tid ~= '' then
    browser.stoptask(tid,'User requested')
    tab.icon = '@ICON_STOP'
    tab.toolbar:eval('MarkAsStopped()')
    SessionManager:setsessionstatus(sesname, 'Canceled')
  end
end

function SyhuntCode:AddToTargetList(reptype)
  reptype = reptype or 'git'
  local d = {}
  d.title = 'Add Code Target'
  d.name_caption = 'Name (eg: MyProject)'
  if reptype == 'git' then
    d.value_caption = 'GIT URL (eg: https://github.com/syhunt/vulnphp.git)'
  end
  if reptype == 'gita' then
    d.value_caption = 'Azure DevOps Services GIT URL (eg: https://dev.azure.com/user/myproject/_git/myproject)'
  end
  if reptype == 'ados' then
    d.value_caption = 'Azure DevOps Services TFS URL (eg: https://dev.azure.com/user/myproject)'
  end
  if reptype == 'tfs' then
    d.value_caption = 'TFS URL (eg: https://myserver/tfs/myproject or collection:https://myserver/collection$/serverpath)'
  end  
  local r = Sandcat.Preferences:EditNameValue(d)
  if r.res == true then
    local item  = {}
    item.name = r.name
    item.url = r.value
    item.repeaturlallow = false
    item.repeaturlwarn = true    
    --item.url = SyhuntCode:NormalizeTargetURL(item.url)
    HistView:AddURLLogItem(item, 'Target Repositories')
    self:ViewTargetList(false)
  end
end

function SyhuntCode:DoTargetListAction(action, itemid)
  local item = HistView:GetURLLogItem(itemid, 'Target Repositories')
  if item ~= nil then
    if action == 'scan' then
      prefs.set('syhunt.code.options.target.type', 'url')
      prefs.set('syhunt.code.options.target.url', item.url)
      self:NewScanDialog()
    end
  end
end

function SyhuntCode:ViewTargetList(newtab)
 local t = {}
 t.newtab = newtab
 t.toolbar = 'SyHybrid.scx#code/histview_tbtargets.html'
 t.histname = 'Target Repositories'
 t.tabicon = 'url(SyHybrid.scx#images\\16\\code_bookmarks.png);'
 t.style = [[
  ]]
 t.menu = [[
  <li onclick="SyhuntCode:DoTargetListAction('scan','%i')">Scan Repository...</li>
  <hr/>
  <li onclick="HistView:DeleteURLLogItem('%i','Target Repositories')">Delete</li>
  ]]  
 HistView = HistView or Sandcat:require('histview')  
 HistView:ViewURLLogFile(t)
end

function SyhuntCode:ViewVulnerabilities()
  local sesname = tab:userdata_get('session','')
  if sesname ~= '' then
      SessionManager:show_sessiondetails(sesname)
  else
    app.showmessage('No session loaded.')
  end
end