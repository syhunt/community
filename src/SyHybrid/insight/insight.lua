SyhuntInsight = {}
SyhuntInsight.logfilter = 'Web Server Log files|*.log;access_log*|All files (*.*)|*.*'

function SyhuntInsight:Load()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyForensic.ico'
	self:NewTab()
	app.seticonfromfile(mainico)
	browser.info.fullname = 'Syhunt Forensic'
	browser.info.name = 'Forensic'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntForensic'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#insight/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("results");')
	PageMenu.newtabscript = 'SyhuntInsight:NewTab()'
end

function SyhuntInsight:LoadAttackLog(filename)
  if ctk.file.exists(filename) then
    local slp = ctk.string.loop:new()
    slp:loadfromfile(filename)
    while slp:parsing() do
      tab:results_add(ctk.base64.decode(slp.current))
    end
    tab.status = string.format('Found %i possible attacks.', slp.count)
    slp:release()
  end
end

function SyhuntInsight:LoadSession(sesname)
  debug.print('Loading Forensic session: '..sesname)
  if self:NewTab() ~= '' then
   tab:userdata_set('session',sesname)
   tab:userdata_set('taskid','')
   local s = symini.session:new()
   s.name = sesname
   local logfile = s:getvalue('target file')
   local attacklogfile = s:getdir()..'\AttacksCustom.log'
   if logfile ~= '' then
    self.ui.file.value = logfile
    self:LoadAttackLog(attacklogfile)
   end
   tab.title = sesname
   if s:getvalue('attacks') ~= '0' then
     tab.toolbar:eval('MarkAsAttacked()')
   else
     tab.toolbar:eval('MarkAsSecure()')
   end
   if s:getvalue('breached') == 'True' then
     tab.toolbar:eval('MarkAsBreached()')
   end
   s:release()
 end
end

function SyhuntInsight:EditPreferences()
	local slp = ctk.string.loop:new()
	local t = {}
	local cs = symini.insight:new()
	slp:load(cs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,cs:prefs_getdefault(slp.current))
	end
	t.html = SyHybrid:getfile('insight/prefs/prefs.html')
	t.html = ctk.string.replace(t.html,'%insight_checks%',SyHybrid:GetOptionsHTML(cs.options_checks))
	t.id = 'syhuntinsight'
	t.options = cs.options
	t.options_disabled = cs.options_locked
	Sandcat.Preferences:EditCustom(t)
	cs:release()
	slp:release()
end

function SyhuntInsight:NewScan()
  if self:IsScanInProgress(true) == false then
    local ui = self.ui
    ui.file.value = ''
    tab:results_clear()
  	tab:userdata_set('session','')
  	tab:userdata_set('taskid','')
	  tab:runsrccmd('showmsgs',false)
	  tab.toolbar:eval('MarkReset();')
	  tab.status = ''
	  tab.icon = '@ICON_EMPTY'
	  tab.title = 'New Scan'
	end
end

function SyhuntInsight:LoadAttackerProfile(ip)
  if AttackerProfile == nil then
    SyHybrid:dofile('insight/profile.lua')
  end
  AttackerProfile:load(ip)
end

function SyhuntInsight:NewScanDialog()
  local tab = self:NewTab()
  if tab ~= '' then
     self:ScanSelectedFile('')
  end 
end

function SyhuntInsight:NewTab()
  local cr = {}
  cr.dblclickfunc = 'SyhuntInsight:LoadAttackerProfile'
  cr.columns = SyHybrid:getfile('insight/atkcols.lst')
	local j = {}
	if browser.info.initmode == 'syhuntinsight' then
	  j.icon = '@ICON_EMPTY'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\forensic.png)'
	end
	j.title = 'New Tab'
	j.toolbar = 'SyHybrid.scx#insight\\toolbar\\toolbar.html'
	j.table = 'SyhuntInsight.ui'
	j.activepage = 'results'
	j.showpagestrip = true
	local newtab = browser.newtabx(j)
	if newtab ~= '' then 
	  tab:results_customize(cr)
	  browser.setactivepage(j.activepage)
	end
	return newtab
end

function SyhuntInsight:Search()
  local ui = self.ui
  if ui.file.value ~= '' then
	  PenTools:PageFind()
	  SearchSource:search(ui.search.value)
	end
end

function SyhuntInsight:SaveSessionFile(session,filename,filter,defext,sug)
  local saved = false
  session = session or tab:userdata_get('session','')
	if session ~= '' then
	  local source = symini.info.sessionsdir..session..'\\'..filename
	  if ctk.file.exists(source) == true then
	    saved = true
  	  local dest = app.savefile(filter,defext,sug)
  	  if dest ~= '' then
  	    if ctk.file.canopen(source) == true then
  	      ctk.file.copy(source,dest)
  	    else
	        app.showmessage('Unable to save file right now. Please try again.')
  	    end
  	  end
  	end
	end
	if saved == false then
	  app.showmessage('No results to save.')
	end
end

function SyhuntInsight:SaveResults(session)
  local flt = 'Forensic results (*.txt)|*.txt'
  local sug = ctk.file.getname(self.ui.file.value)..'_attacks.txt'
  self:SaveSessionFile(session,'Attacks.log',flt,'txt',sug)
end

function SyhuntInsight:SaveAttackerList(session)
  local flt = 'Forensic attacker list (*.lst)|*.lst'
  local sug = ctk.file.getname(self.ui.file.value)..'_attackers.lst'
  self:SaveSessionFile(session,'Attackers.lst',flt,'lst',sug)
end

function SyhuntInsight:PauseScan()
  local tid = tab:userdata_get('taskid','')
  if tid ~= '' then
    browser.suspendtask(tid)
  end
end

function SyhuntInsight:StopScan()
  local tid = tab:userdata_get('taskid','')
  if tid ~= '' then
    browser.stoptask(tid,'User requested')
    tab.icon = '@ICON_STOP'
    tab.toolbar:eval('MarkAsStopped()')
  end
end

function SyhuntInsight:IsScanInProgress(warn)
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

function SyhuntInsight:ReScanFile()
  if self:IsScanInProgress(true) == false then
    self:ScanFile(self.ui.file.value,'rescan')
  end
end

function SyhuntInsight:ScanFile(filename,huntmethod,targetip)
  local ui = self.ui
  local huntmethod = huntmethod or 'normal'
  local targetip = targetip or ''
  if SyHybridUser:IsMethodAvailable(huntmethod, true) then
	  if filename ~= '' then
	    tab:results_clear()
	    tab.title = ctk.file.getname(filename)
	    if ctk.file.getsize(filename) < 1024*500 then
	      tab:runsrccmd('loadfromfile',filename)
	    else
	      tab.source = ''
	    end
	    ui.file.value = filename
  		prefs.save()
  		local script = SyHybrid:getfile('insight/scantask.lua')
  		local j = ctk.json.object:new()
  	  j.sessionname = symini.getsessionname()
  	  j.targetip = targetip
  		if huntmethod == 'reconstruct' then
  	    j.sessionname = ''
  	    tab.title = tab.title..': '..targetip..' Session Reconstruction'
  	  elseif huntmethod == 'rescan' then
  	    j.sessionname = ''
  	  end
  		tab:userdata_set('session',j.sessionname)
  		j.logfile = filename
  		j.huntmethod = huntmethod
		  local menu = SyHybrid:getfile('insight/scantaskmenu.html')
	  	menu = ctk.string.replace(menu,'%s',j.sessionname)
  		local tid = tab:runtask(script,tostring(j),menu)
  		tab:userdata_set('taskid',tid)
  		j:release()
  		browser.setactivepage('results')
  	end
  end
end

function SyhuntInsight:ScanSelectedFile(huntmethod)
  if SyHybridUser:IsMethodAvailable(huntmethod, true) then
	  local filename = app.openfile(self.logfilter,'log')
	  if filename ~= '' then
	    self:ScanFile(filename,huntmethod)
	  end
  end
end
