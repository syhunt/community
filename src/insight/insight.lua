SyhuntInsight = {}
SyhuntInsight.logfilter = 'Web Server Log files|*.log;access_log*|All files (*.*)|*.*'

function SyhuntInsight:Load()
  local mainexe = app.dir..'SyInsight.exe'
	self:NewTab()
	app.seticonfromfile(mainexe)
	browser.info.fullname = 'Syhunt Insight'
	browser.info.name = 'Insight'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntInsight'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#insight/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("resources");')
	PageMenu.newtabscript = 'SyhuntInsight:NewTab()'
end

function SyhuntInsight:EditPreferences()
	local slp = slx.string.loop:new()
	local t = {}
	local cs = symini.insight:new()
	slp:load(cs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,cs:prefs_getdefault(slp.current))
	end
	t.pak = SyHybrid.filename
	t.filename = 'insight/prefs/prefs.html'
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
    tab:resources_clear()
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
  SyHybrid:dofile('insight/profile.lua')
  AttackerProfile:load(ip)
end

function SyhuntInsight:NewTab()
  local colloader = 'SyhuntInsight:LoadAttackerProfile'
  local col =
[[
"c=Line",w=80
"c=Date / Time",w=180
"c=Attacker IP",w=100
"c=Request",a=1,w=200
"c=Status",w=80
"c=Attack Description",w=140
"c=Attack Origin",w=100
"c=Tool",w=120
]]
	local j = {}
	if browser.info.initmode == 'syhuntinsight' then
	  j.icon = '@ICON_EMPTY'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\insight.png)'
	end
	j.title = 'New Tab'
	j.toolbar = 'SyHybrid.scx#insight\\toolbar\\toolbar.html'
	j.table = 'SyhuntInsight.ui'
	j.activepage = 'resources'
	j.showpagestrip = true
	local newtab = browser.newtabx(j)
	if newtab ~= '' then 
	  tab:resources_loadcol(col,colloader)
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
	  local source = symini.getsessionsdir()..session..'\\'..filename
	  if slx.file.exists(source) == true then
	    saved = true
  	  local dest = app.savefile(filter,defext,sug)
  	  if dest ~= '' then
  	    if slx.file.canopen(source) == true then
  	      slx.file.copy(source,dest)
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
  local flt = 'Insight results (*.txt)|*.txt'
  local sug = slx.file.getname(self.ui.file.value)..'_attacks.txt'
  self:SaveSessionFile(session,'Attacks.log',flt,'txt',sug)
end

function SyhuntInsight:SaveAttackerList(session)
  local flt = 'Insight list (*.lst)|*.lst'
  local sug = slx.file.getname(self.ui.file.value)..'_attackers.lst'
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
    tab.icon = '@ICON_EMPTY'
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
	    tab:resources_clear()
	    tab.title = slx.file.getname(filename)
	    if slx.file.getsize(filename) < 1024*500 then
	      tab:runsrccmd('loadfromfile',filename)
	    else
	      tab.source = ''
	    end
	    ui.file.value = filename
  		prefs.save()
  		local script = SyHybrid:getfile('insight/scantask.lua')
  		local j = slx.json.object:new()
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
		  local menu = [[
		  <li onclick="browser.showbottombar('taskmon')">View Messages</li>
		  <!--li onclick="SessionManager:show_sessiondetails('%s')">View Vulnerabilities</li-->
	  	<!--li style="foreground-image: url(SyHybrid.scx#images\16\saverep.png);" onclick="ReportMaker:loadtab('%s')">Generate Report</li-->
	  	<li style="foreground-image: @ICON_SAVE" onclick="SyhuntInsight:SaveResults('%s')">Save Results</li>
	  	<li style="foreground-image: @ICON_SAVE" onclick="SyhuntInsight:SaveAttackerList('%s')">Save Attacker List</li>
	  	]]
	  	menu = slx.string.replace(menu,'%s',j.sessionname)
  		local tid = tab:runtask(script,tostring(j),menu)
  		tab:userdata_set('taskid',tid)
  		j:release()
  		browser.setactivepage('resources')
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
