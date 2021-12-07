
SyhuntIcy = {}

function SyhuntIcy:Load()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyIcyDark.ico'
	self:NewTab()
    app.seticonfromfile(mainico)
	browser.info.fullname = 'Syhunt IcyDark'
	browser.info.name = 'Icy'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntIcyDark'
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
  local filename = app.openfile('Syhunt IcyDark Dump file (*.icyd)|*.icyd','icyd')
  if filename ~= '' then
    local id = symini.icydark:new()
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
   local id = symini.icydark:new()
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
	local hs = symini.icydark:new()
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
	local cs = symini.icydark:new()
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
      if target.type == 'file' then
        target.file = prefs.get('syhunt.icydark.options.target.file','')
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
	  j.icon = 'url(SyHybrid.scx#images\\16\\icydark.png)'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\icydark2.png)'
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
  if self.CheckDepend() == true then
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

function SyhuntIcy:DoTargetListAction(action, itemid)
  local item = HistView:GetURLLogItem(itemid, 'Targets Dark')
  if item ~= nil then
    if action == 'scan' then
      prefs.set('syhunt.icydark.options.target.url', item.url)
      self:NewScanDialog()
    end        
    if action == 'editprefs' then
      local ok = self:EditDomainPreferences(item.url)
      if ok == true then
        self:ViewTargetList(false)
      end
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
  d.title = 'Add IcyDark Target'
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
    self:ViewTargetList(false)
  end
end

function SyhuntIcy:ViewTargetList(newtab)
 local t = {}
 t.newtab = newtab
 t.toolbar = 'SyHybrid.scx#icy/histview_tbtargets.html'
 t.histname = 'Targets Dark'
 t.tabicon = 'url(SyHybrid.scx#images\\16\\icydiver.png);'
 t.style = [[
  ]]
 t.menu = [[
  <li onclick="SyhuntIcy:DoTargetListAction('scan','%i')">Scan Domain...</li>
  <hr/>
  <li onclick="HistView:DeleteURLLogItem('%i','Targets Dark')">Delete</li>
  ]]  
 HistView = HistView or Sandcat:require('histview')  
 HistView:ViewURLLogFile(t)
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