
SyhuntIcy = {}

function SyhuntIcy:Load()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyBreach.ico'
	self:NewTab()
    app.seticonfromfile(mainico)
	browser.info.fullname = 'Syhunt Breach Scanner'
	browser.info.name = 'Breach'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntBreach'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#code/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("results");')
	PageMenu.newtabscript = 'SyhuntIcy:NewTab()'
end

-- This function helps confirm a leaked password through a dump generated hash
function SyhuntIcy:ConfirmPassHash(maskedpw,hash)
  local pass = app.showinputdialogpw(maskedpw..':','')
  if pass ~= '' then
    if symini.icy_matchpasshash(pass,hash) == true then
      app.showmessage('Perfect match!')
    else
      app.showalert('Wrong password!')
      self:ConfirmPassHash(maskedpw,hash)
    end
  end
end

function SyhuntIcy:ConfirmPassHashFromPassTab(s)
  self:ConfirmPassHash('Enter the password', s)
end

-- This function helps confirm a leaked file through a dump generated hash
function SyhuntIcy:ConfirmFileHash(filename,hash)
  local file = app.openfile('*.*',ctk.file.getext(filename),filename)
  if file ~= '' then
    if symini.icy_matchfilehash(file,hash) == true then
      app.showmessage('Perfect match!')
    else
      app.showalert('Wrong file!')
      self:ConfirmFileHash(filename,hash)
    end
  end
end
function SyhuntIcy:ImportDump()
  local filename = app.openfile('Syhunt Breach Dump file (*.icyd)|*.icyd','icyd')
  if filename ~= '' then
    local id = symini.breach:new()
    id:start()
    local imp = id:importdump(filename)
      if imp.b == false then
        app.showalert(imp.s)  
      else
        app.showmessagesmpl(imp.s)    
      end
    id:release()
  end
end

function SyhuntIcy:CheckDepend()
   local success = false
   local id = symini.breach:new()
   id:start()
   success = id:checkdepend().b
   id:release()
   return success
end

function SyhuntIcy:GetTargetListHTML()
  return SyhuntDynamic:GetTargetListHTML()
end

function SyhuntIcy:LoadProgressPanel()
    local k = SyHybridUser.ptkdetails
    local logos = ''
    local html = SyHybrid:getfile('icy/progress.html')
    --if k.lang_web == true then
    --  logos = logos..'<img src="SyHybrid.scx#images\\misc\\syhunt-logo-web.png">'
    --end
    --if k.lang_mobile == true then
    --  logos = logos..'<img src="SyHybrid.scx#images\\misc\\syhunt-logo-mobile.png">'
    --end
    --logos = logos..SyHybridUser:GetEditionLogo()
    html = ctk.string.replace(html, '<!--logoplus-->',logos)
    tab:results_loadx(html)
end

function SyhuntIcy:ClearResults()
  if self:IsScanInProgress(true) == false then
      local ui = self.ui
      ui.url.value = ''
	  tab:tree_clear()
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

function SyhuntIcy:EditLeakDetails(filename)
  if VulnInfo == nil then
    SyHybrid:dofile('hybrid/vulninfo.lua')
  end
  VulnInfo:editvulnfile_custom(filename, 'icy/prefs_leak/prefs.html')
end

function SyhuntIcy:EditDomainPreferences(url)
    local res = false
	local slp = ctk.string.loop:new()
	local hs = symini.breach:new()
	local jsonfile = hs:getdomainprefsfilename(url)
	hs:start()
	slp:load(hs.options)
	while slp:parsing() do
	  prefs.regdefault(slp.current,hs:prefs_getdefault(slp.current))
    end
	local t = {}
	t.html = SyHybrid:getfile('icy/prefs_domain/prefs.html')
	t.id = 'syhuntdomainprefs'
	t.options = hs.options
	t.jsonfile = jsonfile
	res = Sandcat.Preferences:EditCustomFile(t)
	hs:release()
	slp:release()
	return res
end

function SyhuntIcy:EditPreferences(html)
	html = html or SyHybrid:getfile('icy/prefs/prefs.html')
	local slp = ctk.string.loop:new()
	local t = {}
	local cs = symini.breach:new()
	cs:start()
	slp:load(cs.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,cs:prefs_getdefault(slp.current))
	end
	t.html = html
	t.html = ctk.string.replace(t.html,'%icy_checks%',SyHybrid:GetOptionsHTML(cs.options_checks))
	t.id = 'syhunticy'
	t.options = cs.options
	t.options_disabled = cs.options_locked
	local res = Sandcat.Preferences:EditCustom(t)
	cs:release()
	slp:release()
	return res
end

function SyhuntIcy:IsScanInProgress(warn)
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

function SyhuntIcy:NewScan()
  local canscan = true
  if runinbg == false then
    if self:IsScanInProgress(true) == true then
      canscan = false
    end
  end
  if canscan == true then
    self:ClearResults()
    local html = SyHybrid:getfile('icy/prefs_scan/prefs.html')
    html = ctk.string.replace(html,'%dark_targets%',self:GetTargetListHTML())    
    html = ctk.string.replace(html,'%dynamic_targets%',SyhuntDynamic:GetTargetListHTML())
    local ok = self:EditPreferences(html)
    if ok == true then
      local editdomainprefs = prefs.get('syhunt.icydark.options.target.editdomprefs',false)
      local target = {}
      target.type = prefs.get('syhunt.icydark.options.target.type','url')
      if target.type == 'url' then
        target.url = prefs.get('syhunt.icydark.options.target.url','')
      end
      local huntmethod = prefs.get('syhunt.icydark.options.huntmethod','darkplus')
      if editdomainprefs == true then
          ok = self:EditDomainPreferences(target.url)
      end  
      if ok == true then    
        self:ScanTarget(huntmethod, target)
      end
    end
  end
end

function SyhuntIcy:NewTab()
    local cr = {}
    cr.dblclickfunc = 'SyhuntIcy:EditLeakDetails'
    cr.columns = SyHybrid:getfile('icy/leakcols.lst')
	local j = {}
	if browser.info.initmode == 'syhunticy' then
	  j.icon = 'url(SyHybrid.scx#images\\16\\breach.png)'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\breach.png)'
	end
	j.title = 'New Tab'
	j.toolbar = 'SyHybrid.scx#icy\\toolbar\\toolbar.html'
	j.table = 'SyhuntIcy.ui'
	j.activepage = 'results'
	j.showpagestrip = true
	local newtab = browser.newtabx(j)
	if newtab ~= '' then
	    tab.showtree = true
		browser.setactivepage(j.activepage)
		--browser.pagebar:eval('Tabs.Select("source");')
		tab:results_customize(cr)
        self:LoadProgressPanel()
	end
	return newtab
end

function SyhuntIcy:NewScanDialog()
  if self:CheckDepend() == true then
    local tab = self:NewTab()
    if tab ~= '' then
       self:NewScan()
    end
  end 
end

function SyhuntIcy:ScanTarget(huntmethod, target)
  local ui = self.ui
  huntmethod = huntmethod or 'darkplus'
  target.url = target.url or ''
  target.file = target.file or ''
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
  		--self:SetCodeDirectory(target.dir)
  		local tid = 0
  		local script = SyHybrid:getfile('icy/scantask.lua')
  		local j = ctk.json.object:new()
	  	j.sessionname = symini.getsessionname()
  		tab:userdata_set('session',j.sessionname)
  		j.targettype = target.type
  		j.icyurl = target.url
  		ui.url.value = target.url
  		j.icyfile = target.file
  		j.runinbg = false
  		j.huntmethod = huntmethod
		  local menu = [[
		  <!--li onclick="browser.showbottombar('task messages')">View Messages</li-->
		  <li onclick="SessionManager:show_sessiondetails('%s')">View Threats</li>
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

function SyhuntIcy:IsDomainAuthorized(domain)
  local b = symini.breach:new()
  local resbool = b:getdomaindetails(domain).authorized
  b:release()
  return resbool
end

function SyhuntIcy:DoMonitorAction(action, itemid)
  local item = HistView:GetURLLogItem(itemid, 'Targets Dark')
  if item ~= nil then
    if action == 'scan' then
      if self:IsDomainAuthorized(item.url) == false then
        app.showmessage('Results will be redacted (Domain not authorized).')    
      end
      prefs.set('syhunt.icydark.options.target.checksubdom', true)
      local tab = self:NewTab()
      if tab ~= '' then      
        self:ScanTarget('darkplus', item)
      end
    end        
    if action == 'scancustom' then
      prefs.set('syhunt.icydark.options.target.url', item.url)
      self:NewScanDialog()
    end    
    if action == 'viewpwdlist' then
      if self:IsDomainAuthorized(item.url) == true then
        self:NewPassTab('?domain='..item.url)
      else
        app.showalert('No permission to view password list for this domain.')
      end
    end   
    if action == 'viewfilelist' then
      self:ViewLeakedFiles('?domain='..item.url)
    end               
    if action == 'editprefs' then
      local ok = self:EditDomainPreferences(item.url)
      if ok == true then
        self:ViewTargetList(false)
      end
    end
    if action == 'delete' then
      HistView:DeleteURLLogItem(itemid,symini.info.breachdomainlistname)
      local jsonfile = symini.info.configdir..'\\Domain\\'..item.name..'.json'
      ctk.file.delete(jsonfile)
      self:ViewTargetList(false)
    end    
  end
end

function SyhuntIcy:GetTargetListHTML()
  local histfile = browser.info.configdir..'Targets Dark'..'.sclist'
  local html = ''
  if ctk.file.exists(histfile) == true then
    local slp = ctk.string.loop:new()
    slp:loadfromfile(histfile)
     while slp:parsing() do
       local url = ctk.string.after(slp.current, 'url="')
       url = ctk.string.before(url,'"')
       html = html..'<li class="urlsetter" targeturl="'..url..'">'..url..'</li>'
     end
    slp:release()
  end
  return html
end

function SyhuntIcy:AddToTargetList()
  local d = {}
  d.title = 'Add Breach Target'
  d.name_caption = 'Name (eg: MySite)'
  d.value_caption = 'Domain (eg: syhunt.com)'
  local r = Sandcat.Preferences:EditNameValue(d)
  if r.res == true then
    local item  = {}
    item.name = r.name
    item.url = r.value
    item.repeaturlallow = false
    item.repeaturlwarn = true
    HistView:AddURLLogItem(item, 'Targets Dark')
    self:LoadTargetList()
    --self:ViewTargetList(false)
  end
end

function SyhuntIcy:GetMonitoredDomainList()
  HistView = HistView or Sandcat:require('histview')  
  return HistView:GetURLLogLists(symini.info.breachdomainlistname).idlist
end

function SyhuntIcy:GetMonitorIcons(d)
  local icons = {}
  icons.score = 'Resources.pak#16/icon_blank.png'
  if d.score ~= 0 then 
    icons.score = 'SyHybrid.scx#images/16/score_'..string.lower(d.scorename)..'.png'
  end
  return icons
end

function SyhuntIcy:IncludeMonitoredDomainItem(tb, id)
  local histitem = HistView:GetURLLogItem(id, symini.info.breachdomainlistname)
  local domname = histitem.name
  local d = symini.icy_getdomaindetails(histitem.url)
  local icons = self:GetMonitorIcons(d)
  local title = d.name
  if d.name == '' then
    if ctk.string.matchx(domname, '#*-*#') == true then
    title = 'Untitled: '..domname
    else
    title = domname
    end
  end
  local menu =  [[
  <menu.context id="menu%i">
  <li onclick="SyhuntIcy:DoMonitorAction('scan','%i')">List All Breaches...</li>
  <li onclick="SyhuntIcy:DoMonitorAction('viewpwdlist','%i')">View Leaked Passwords</li>
  <li onclick="SyhuntIcy:DoMonitorAction('viewfilelist','%i')">View Leaked Files</li>
  <hr/>  
  <li onclick="SyhuntIcy:DoMonitorAction('editprefs','%i')">Edit Domain Preferences...</li>
  <hr/>  
  <li onclick="SyhuntIcy:DoMonitorAction('scancustom','%i')">List Breaches (Custom)...</li>
  <hr/>
  <li onclick="SyhuntIcy:DoMonitorAction('delete','%i')">Delete</li>
  </menu>
  ]]  
  local troption = '<tr role="option" style="context-menu: selector(#menu%i);" ondblclick="SyhuntIcy:DoMonitorAction([[editprefs]],[[%i]])">'
  troption = ctk.string.replace(troption, '%i', id)
  tb:add(troption)
  tb:add('<td>'..ctk.html.escape(title)..'</td>')
  tb:add('<td>'..ctk.html.escape(histitem.url)..'</td>')
  tb:add('<td><img .lvfileicon src="'..icons.score..'"> '..d.scorename..' ('..tostring(d.score)..')</td><td>'..d.lastruntimedesc..'</td>')    
  tb:add('</tr>')
  menu = ctk.string.replace(menu, '%i', id)
  tb:add(menu)
end

function SyhuntIcy:LoadIntroScreen(html)
  local t = {}
  t.title = 'Score & Breaches'
  t.toolbar = 'SyHybrid.scx#icy/monitor/toolbar.html'
  t.icon = 'url(SyHybrid.scx#images\\16\\icydiver.png);'
  t.html = html
  t.tag = 'breachmonitor'
  browser.newtabx(t)    
end

function SyhuntIcy:LoadTargetList()
  if self:CheckDepend() == true then
    local dmcount = symini.info.breachdomainlistcount
    if dmcount == 0 then
      self:ViewTargetList(true)
    else
       -- Loads Splash screen
       local html = [[
       <center>
       <img src="SyHybrid.scx#images\misc\syhunt-breach-icon.png"><br>
       <h1>Checking score & breaches... Please, wait.</h1>
       </center>]]
       self:LoadIntroScreen(html)
       -- Executes Sandcat task that updates Syhunt Breach Score info and alerts    
      local tid = 0  	
      local menu = ''	
      local script = SyHybrid:getfile('icy/monitortask.lua')
      local j = ctk.json.object:new()
      j.runinbg = false
      j.filename = filename
      tid = tab:runtask(script,tostring(j),menu)
      j:release()
     end
   end
end

function SyhuntIcy:ViewTargetList(newtab)
 local html = SyHybrid:getfile('icy/monitor/list.html')
 local tb = ctk.string.list:new()
 local lp = ctk.string.loop:new()
 lp:load(self:GetMonitoredDomainList())
 while lp:parsing() do
   self:IncludeMonitoredDomainItem(tb, lp.current)
 end 
 html = ctk.string.replace(html, '%monitoreddomains%', tb.text)
 if newtab == false then
   tab:loadx(html)
 else
   SyhuntIcy:LoadIntroScreen(html)
 end
 tb:release()
 lp:release() 
end

function SyhuntIcy:ViewLeakedFiles(domain)
  local b = symini.breach:new()
  b:start()
  local sumfileleak = b:summaryzefileleak(domain)
  if sumfileleak.result == true then
    local html = SyHybrid:getfile('icy/prefs_leak/filelist.html')
    html = ctk.string.replace(html,'%exfil_files%', sumfileleak.resulthtml) 
    html = ctk.string.replace(html,'%exfil_files_notice%', sumfileleak.resultdesc)      
    html = ctk.string.replace(html,'%exfil_files_size%', tostring(sumfileleak.totalsize))
    html = ctk.string.replace(html,'%exfil_files_sizedesc%', sumfileleak.totalsizedesc)   
    app.showdialogx(html)
  else
    app.showalert(sumfileleak.resultdesc)
  end
  b:release()
end

function SyhuntIcy:NewPassTab(filename)
  local cr = {}
  cr.dblclickfunc = 'SyhuntIcy:ConfirmPassHashFromPassTab'
  cr.columns = SyHybrid:getfile('icy/passcols.lst')
	local j = {}
	if browser.info.initmode == 'syhunticydark' then
	  j.icon = '@ICON_EMPTY'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\icydark.png)'
	end
	j.title = 'Leaked Passwords'
	--j.toolbar = 'SyHybrid.scx#insight\\toolbar\\toolbar.html'
	j.table = 'SyhuntIcy.ui'
	j.activepage = 'results'
	j.showpagestrip = false
	local newtab = browser.newtabx(j)
	if newtab ~= '' then 
	  tab:results_customize(cr)
	  browser.setactivepage(j.activepage)
	end
   -- Executes Sandcat task
  local tid = 0  	
  local menu = ''	
  local script = SyHybrid:getfile('icy/passtask.lua')
  local j = ctk.json.object:new()
  j.runinbg = false
  j.filename = filename
  tid = tab:runtask(script,tostring(j),menu)
  tab:userdata_set('taskid',tid)
  j:release()
  browser.setactivepage('results')
end