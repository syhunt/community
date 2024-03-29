SyhuntDynamic = {}
SyhuntDynamic.waitlogin = false
SyhuntDynamic.title = 'Syhunt Dynamic'

function dynamictargetchanged(t)
    --if app.ask_yn('Do you wish to scan logged URL: '..t.url..'?') == true then
    if SyhuntDynamic.waitlogin == true then
      SyhuntDynamic.waitlogin = false
      browser.options.showbottombar = false
      SyhuntDynamic:SetURLCookie(t)
      app.bringtofront()
      SyhuntDynamic:NewScanDialog()
    end
end

function SyhuntDynamic:AddCommands()
	console.addcmd('appscan',"SyhuntDynamic:ScanThisSite('appscan')",'Scans the current site')
	console.addcmd('spider',"SyhuntDynamic:ScanThisSite('spider')",'Spiders the current site')
end

function SyhuntDynamic:AddClipmon()
  clipmon = symini.clipmon:new()
  clipmon.ontargetchanged = dynamictargetchanged
end

function SyhuntDynamic:ManualLogin()
  if SyHybridUser:IsOptionAvailable(true) == true then
    self.waitlogin = true
    local html = clipmon:getloginhelp()
    browser.loadpagex({name='manual login help',html=html})
  end
end

function SyhuntDynamic:CaptureCookie(onlogscript)
 if tab:hasloadedurl(true) then
  local onlogscript = onlogscript or ''
  --tab:runluaonlog('"done"','SyhuntDynamic:SetURLCookieFromSandcat() '..onlogscript)
  --tab:runjs([[results={};results.ck=document.cookie;results.ua=navigator.userAgent;window.chrome.webview.postMessage(results);window.chrome.webview.postMessage('done');]])
  tab:runluaafterjs('SyhuntDynamic:SetURLCookieFromSandcat() '..onlogscript,[[results={};results.ck=document.cookie;results.ua=navigator.userAgent;JSON.stringify(results)]])
 end
end

function SyhuntDynamic:SetURLCookieFromSandcat()
  local j = ctk.json.object:new()
  j:load(tab.lastjsexecresult)
  local t = {}
  t.url = tab.url
  t.cookie = j.ck
  t.useragent = j.ua
  self:SetURLCookie(t)
  j:release()  
end

function SyhuntDynamic:SetURLCookie(t)
  local ldiff = {}
  ldiff.ua = t.useragent
  ldiff.source = tab.source
  ldiff.url = t.url
  local ldiffres = symini.checklogindiff(ldiff)
  prefs.set('syhunt.dynamic.options.target.url', t.url)
  if t.useragent ~= '' then
    prefs.set('syhunt.dynamic.emulation.useragent', t.useragent)
    prefs.set('syhunt.dynamic.emulation.forceuseragent', true)
  end
  -- Saves to site preferences
  --app.showmessage(t.cookie)
  --app.showmessage(t.url)
  symini.prefs_set('dynamic.formauth.logindiff', ldiffres, t.url)  
  symini.prefs_set('dynamic.lists.cookies', t.cookie, t.url)
  symini.prefs_set('dynamic.crawling.autofollowinstarturl', false, t.url)
  tab.status = 'Page session details saved.'
end

function SyhuntDynamic:SaveCapturedURLs()
 local destfile = app.savefile('Syhunt URL list (*.lst)|*.lst','lst','')
 if destfile ~= '' then
   local sl = ctk.string.list:new()
   sl.text = tab.urllist
   sl:savetofile(destfile)
   sl:release()
 end
end

function SyhuntDynamic:CaptureURLsEnd()
	if tab:hasloadedurl(true) then
		tab.captureurls = true
		app.showmessage('URL Logger enabled.')
	end
end

function SyhuntDynamic:CaptureURLs()
    browser.setactivepage('browser')
    local url = app.showinputdialog('Start URL:', '', 'Start URL')
    tab.loadend = 'SyhuntDynamic:CaptureURLsEnd()'
    if url ~= '' then
      tab:gotourl(url)
    end
end

function SyhuntDynamic:ClearResults()
  if self:IsScanInProgress(true) == false then
    local ui = self.ui
    ui.url.value = ''
    tab:results_clear()
    tab:tree_clear()
  	tab:userdata_set('session','')
  	tab:userdata_set('taskid','')
	tab:runsrccmd('showmsgs',false)
	tab.toolbar:eval('MarkReset();')
	tab.status = ''
	tab.icon = 'url(SyHybrid.scx#images\\16\\dynamic.png)'
	tab.title = 'New Tab'
	self:LoadProgressPanel()
  end
end

function SyhuntDynamic:EditPreferences(html)
	html = html or SyHybrid:getfile('dynamic/prefs/prefs.html')
	local slp = ctk.string.loop:new()
	local ds = symini.dynamic:new()
	ds:start()
	slp:load(ds.options)
	while slp:parsing() do
		prefs.regdefault(slp.current,ds:prefs_getdefault(slp.current))
	end
	html = ctk.string.replace(html,'%dynamic_checks%',SyHybrid:GetOptionsHTML(ds.options_checks))
	html = ctk.string.replace(html,'%dynamic_injection_checks%',SyHybrid:GetOptionsHTML(ds.options_checksinj))
	local t = {}
	t.html = html
	t.id = 'syhuntdynamic'
	t.options = ds.options
	t.options_disabled = ds.options_locked
	local res = Sandcat.Preferences:EditCustom(t)
	ds:release()
	slp:release()
	return res
end

function SyhuntDynamic:EditNetworkPreferences()
    local html = SyHybrid:getfile('dynamic/prefs_net/prefs.html')
	self:EditPreferences(html)
end

function SyhuntDynamic:EditSitePreferences(url)
    url = url or tab.url
    local res = false
	if ctk.string.beginswith(string.lower(url),'http') then
		local jsonfile = prefs.getsiteprefsfilename(url)
		local slp = ctk.string.loop:new()
		local hs = symini.hybrid:new()
		hs:start()
		slp:load(hs.options)
		while slp:parsing() do
			prefs.regdefault(slp.current,hs:prefs_getdefault(slp.current))
		end
		local css = ''
		if prefs.get('syhunt.hybrid.advanced.ai.openai.apikey.encrypted','') == '' then
		  css = '.aioption { display:none; }'
		end
		local html = SyHybrid:getfile('dynamic/prefs_site/prefs.html')
		html = ctk.string.replace(html,'%css%',css)
		local t = {}
		t.html = html
		t.id = 'syhuntsiteprefs'
		t.options = hs.options
		t.jsonfile = jsonfile
		res = Sandcat.Preferences:EditCustomFile(t)
		--app.showmessage(tostring(res))
		hs:release()
		slp:release()
	else
		app.showmessage('No site loaded.')
	end
	return res
end

function SyhuntDynamic:GenerateReport()
  local sesname = tab:userdata_get('session','')
  if sesname ~= '' then
    ReportMaker:loadtab(sesname)
  else
    app.showmessage('No session loaded.')
  end
end

function SyhuntDynamic:IsScanInProgress(warn)
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

function SyhuntDynamic:Load()
    local mainexe = app.dir..'SyMini.dll'
    local mainico = app.dir..'\\Packs\\Icons\\SyDynamic.ico'
	self:NewTab()
	app.seticonfromfile(mainico)
	browser.info.fullname = 'Syhunt Dynamic'
	browser.info.name = 'Dynamic'
	browser.info.exefilename = mainexe
	browser.info.abouturl = 'http://www.syhunt.com/en/?n=Products.SyhuntDynamic'
	browser.pagebar:eval('Tabs.RemoveAll()')
	browser.pagebar:eval([[$("#tabstrip").insert("<include src='SyHybrid.scx#dynamic/pagebar.html'/>",1);]])
	browser.pagebar:eval('SandcatUIX.Update();Tabs.Select("results");')
	PageMenu.newtabscript = 'SyhuntDynamic:NewTab(false)'
end

function SyhuntDynamic:EditVulnDetails(filename)
  if VulnInfo == nil then
    SyHybrid:dofile('hybrid/vulninfo.lua')
  end
  VulnInfo:editvulnfile(filename)
end

function SyhuntDynamic:LoadVulnDetails(filename)
  if VulnInfo == nil then
    SyHybrid:dofile('hybrid/vulninfo.lua')
  end
  VulnInfo:loadvulnfile(filename)
end

function SyhuntDynamic:LoadURLDetails(url)
  browser.setactivepage('response')
  local ses = symini.session:new()
  local req = {}
  ses.name = tab:userdata_get('session')
  req = ses:getrequestdetails(url,'snapshot.first')
  ses:release()
  tab:response_load(req)
  if req.isseccheck == true then
    if ctk.url.crack(req.url).path ~= '' then
      self:LoadVulnDetails(req.vulnfilename)
    end
  end
end

function SyhuntDynamic:LoadTree(dir)
	tab.showtree = true
	tab.tree_loaditemfunc = 'SyhuntDynamic:LoadURLDetails'
	tab:tree_clear()
	local opt = {}
	opt.dir = dir..'\\'
	opt.recurse = true
	opt.makebold = true
	--opt.affscripts = affscripts
	--tab:tree_loaddir(opt)
end

function SyhuntDynamic:GetTargetListHTML()
  local histfile = browser.info.configdir..'Targets Dynamic'..'.sclist'
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

function SyhuntDynamic:NewScan(runinbg)
  local canscan = true
  if runinbg == false then
    if self:IsScanInProgress(true) == true then
      canscan = false
    end
  end
  if canscan == true then
    prefs.set('syhunt.dynamic.options.target.editsiteprefs',false)
    local html = SyHybrid:getfile('dynamic/prefs_scan/prefs.html')
    html = ctk.string.replace(html,'%dynamic_targets%',SyhuntDynamic:GetTargetListHTML())
    local ok = self:EditPreferences(html)
    if ok == true then
      local targeturl = prefs.get('syhunt.dynamic.options.target.url','')
      local huntmethod = prefs.get('syhunt.dynamic.options.huntmethod','appscan')
      local editsiteprefs = prefs.get('syhunt.dynamic.options.target.editsiteprefs',false)
      if targeturl ~= '' then
        local targeturl_original = self:NormalizeTargetURLEx(targeturl, false)
        local autofollow = symini.prefs_get('dynamic.crawling.autofollowinstarturl', true, targeturl_original)
        targeturl = self:NormalizeTargetURLEx(targeturl, autofollow, false)
        prefs.set('syhunt.dynamic.options.target.url',targeturl)
        if editsiteprefs == true then
          ok = self:EditSitePreferences(targeturl)
        end
        if ok == true then
          self:ScanSite(runinbg,targeturl,huntmethod)
        end
      end
    end
  end
end

function SyhuntDynamic:NewScanDialog()
  local tab = self:NewTab()
  if tab ~= '' then
     self:NewScan(false)
  end 
end

function SyhuntDynamic:NewTab()
  local cr = {}
  cr.dblclickfunc = 'SyhuntDynamic:EditVulnDetails'
  cr.columns = SyHybrid:getfile('dynamic/vulncols.lst')
	local j = {}
	if browser.info.initmode == 'syhuntdynamic' then
	  j.icon = '@ICON_EMPTY'
	else
	  j.icon = 'url(SyHybrid.scx#images\\16\\dynamic.png)'
	end
	j.title = 'New Tab'
	j.toolbar = 'SyHybrid.scx#dynamic\\toolbar\\toolbar.html'
	j.table = 'SyhuntDynamic.ui'
	j.activepage = 'results'
	j.showpagestrip = true
	local newtab = browser.newtabx(j)
	if newtab ~= '' then 
	  self:LoadTree('')
	  tab:results_customize(cr)
      self:LoadProgressPanel()
	  browser.setactivepage(j.activepage)
	  app.update()
	end
	return newtab
end

function SyhuntDynamic:LoadProgressPanel()
  local defstats = [[
    s=code.stats-links,v=1
  ]]
  local logos = ''
  local html = SyHybrid:getfile('dynamic/progress.html')
  logos = logos..SyHybridUser:GetEditionLogo()
  html = ctk.string.replace(html, '<!--logoplus-->',logos)
  tab:results_loadx(html)
  tab:results_updatehtml(defstats)
end

function SyhuntDynamic:NormalizeTargetURLEx(url, autofollow, askfollow)
  askfollow = askfollow or false
  url = self:NormalizeTargetURL(url)
    local redir = symini.checkurlredir(url)
    if redir.result == true and redir.ondomain == false then
      if autofollow == true then
        url = redir.url
      else
        if askfollow == true then
          if app.ask_yn('Follow redirect (recommended) to ['..redir.url..']?') == true then
            url = redir.url
          end
        end
      end
    end
  return url
end

function SyhuntDynamic:NormalizeTargetURL(url)  
  local addproto = true
  if ctk.string.beginswith(string.lower(url),'http:') then
    addproto = false
  elseif ctk.string.beginswith(string.lower(url),'https:') then
    addproto = false
  end
  if addproto then
    url = 'http://'..url
  end
  return url
end

function SyhuntDynamic:PauseScan()
  local tid = tab:userdata_get('taskid','')
  if tid ~= '' then
    browser.suspendtask(tid)
  end
end

function SyhuntDynamic:ScanSite(runinbg,url,method)
	method = method or 'spider'
	if url ~= '' then
		prefs.save()
		tab.captureurls = false
		local script = SyHybrid:getfile('dynamic/scantask.lua')
		local menu = SyHybrid:getfile('dynamic/scantaskmenu.html')
		local j = ctk.json.object:new()
		local tid = 0
		local stat = symini.checkinst()
		j.sessionname = symini.getsessionname()
		j.huntmethod = method
		j.monitor = tab.handle
		j.urllist = tab.urllist
		j.starturl = url
		j.runinbg = runinbg
		menu = ctk.string.replace(menu,'%s',j.sessionname)
		if stat.result == true then
			tid = tab:runtask(script,tostring(j),menu)
		else
			app.showmessage(stat.resultstr)
		end
		if runinbg == false then
		  -- Updates the tab user interface
	  	  self:LoadTree('')
  	      tab:userdata_set('session',j.sessionname)
  	      tab:userdata_set('taskid',tid)
  	      tab.title = ctk.url.crack(url).host
  	      self.ui.url.value = url
  	      browser.setactivepage('results')
		end
		j:release()
	end
end

-- Starts a scan against the loaded web page
function SyhuntDynamic:ScanThisSite_Std(method)
	if tab:hasloadedurl(true) then
	  if SyHybridUser:IsMethodAvailable(method, true) then
		   prefs.set('syhunt.dynamic.options.target.url', tab.url)
		   prefs.set('syhunt.dynamic.options.huntmethod', method)
           self:NewScanDialog()
		  --self:ScanSite(true,tab.url,method)
		end
	end
end

-- Starts a scan against the loaded web page and its cookie data
function SyhuntDynamic:ScanThisSite(method)
  self:CaptureCookie('SyhuntDynamic:ScanThisSite_Std("'..method..'")')
end

function SyhuntDynamic:StopScan()
  local tid = tab:userdata_get('taskid','')
  local sesname = tab:userdata_get('session','')
  if tid ~= '' then
    browser.stoptask(tid,'User requested')
    tab.icon = '@ICON_STOP'
    tab.toolbar:eval('MarkAsStopped()')
    SessionManager:setsessionstatus(sesname, 'Canceled')
  end
end

function SyhuntDynamic:AddToTargetList()
  local d = {}
  d.title = 'Add Dynamic Target'
  d.name_caption = 'Name (eg: MySite)'
  d.value_caption = 'URL'
  local r = Sandcat.Preferences:EditNameValue(d)
  if r.res == true then
    local item  = {}
    item.name = r.name
    item.url = self:NormalizeTargetURLEx(r.value, true)
    item.repeaturlallow = false
    item.repeaturlwarn = true
    HistView:AddURLLogItem(item, 'Targets Dynamic')
    self:ViewTargetList(false)
  end
end

function SyhuntDynamic:AugmentedLoginConfirmSuccess(url)
  browser.options.showbottombar = false
  symini.login_runcmd(url,'applylast')
  app.showmessage('Confirmed!')
end

function SyhuntDynamic:AugmentedLoginPreview(ltype,url,screenshot_url)
  local html = ''
  if ltype == 'AI' then
    html = html..'<button onclick=SyhuntDynamic:AugmentedLoginConfirmSuccess(ctk.base64.decode("'..url..'"))>Confirm Success</button>'
    html = html..'&nbsp;&nbsp;<button onclick=SyhuntDynamic:AugmentedLoginStep(ctk.base64.decode("'..url..'"))>Add New Step</button><br>'
  end
  html = html..'<img src="'..screenshot_url..'">'
  browser.loadpagex({name='ailoginpreview', html=html})
end

function SyhuntDynamic:AugmentedLoginStep(url)
  local action = app.showinputdialog('Describe next action:')
  if action ~= '' then
    self:AugmentedLogin('AI', url, action)
  end
end

function SyhuntDynamic:AugmentedLogin(ltype, url,newstep)
  newstep = newstep or ''
  ltype = ltype or 'AI'
  local script = SyHybrid:getfile('dynamic/logintask.lua')
  local j = ctk.json.object:new()
  j.url = url  
  j.newstep = newstep
  j.type = ltype  
  j.headless = true
  tid = tab:runtask(script,tostring(j),'')
  j:release()
end

function SyhuntDynamic:ClearIncrementalData(tag)
  local d = symini.getincdetails(tag)
  if ctk.file.exists(d.filename) == true then
    ctk.file.delete(d.filename)
    app.showmessage('Incremental cache cleared for this item.')
  else
    app.showalert('No incremental cache found for this item!')  
  end
end

function SyhuntDynamic:DoTargetListAction(action, itemid)
  local item = HistView:GetURLLogItem(itemid, 'Targets Dynamic')
  if item ~= nil then
    if action == 'scan' then
      prefs.set('syhunt.dynamic.options.target.url', item.url)
      self:NewScanDialog()
    end
    if action == 'manuallogin' then
      SyhuntDynamic:ManualLogin(item.url)
    end    
    if action == 'ailogin' then
      SyhuntDynamic:AugmentedLogin('AI', item.url)
    end      
    if action == 'seleniumlogin' then
      SyhuntDynamic:AugmentedLogin('Selenium', item.url)
    end      
    if action == 'seleniumloginui' then
      SyhuntDynamic:AugmentedLogin('SeleniumUI', item.url)
    end          
    if action == 'loginreset' then
      local resp=app.ask_yn('Are you sure you want to reset the AI login cache?',self.title)
      if resp == true then
        symini.login_runcmd(item.url,'resetcache')
        app.showmessage('Done!')
      end
    end       
    if action == 'clearinc' then
      SyhuntDynamic:ClearIncrementalData(item.url)
    end        
    if action == 'editprefs' then
      local ok = self:EditSitePreferences(item.url)
      if ok == true then
        self:ViewTargetList(false)
      end
    end
  end
end

function SyhuntDynamic:ViewTargetList(newtab)
 local t = {}
 t.newtab = newtab
 t.toolbar = 'SyHybrid.scx#dynamic/histview_tbtargets.html'
 t.histname = 'Targets Dynamic'
 t.tabicon = 'url(SyHybrid.scx#images\\16\\dynamic_bookmarks.png);'
 t.readsiteprefs = true
 t.style = [[
  ]]
 t.menu = [[
  <li onclick="SyhuntDynamic:DoTargetListAction('scan','%i')">Scan Site...</li>
  <li onclick="SyhuntDynamic:DoTargetListAction('editprefs','%i')">Edit Site Preferences...</li>
  <hr/>    
  <li>AI-Powered Login
  <menu>
  <li onclick="SyhuntDynamic:DoTargetListAction('ailogin','%i')">Run Test</li>  
  <hr>
  <li onclick="SyhuntDynamic:DoTargetListAction('loginreset','%i')">Reset</li>  
  </menu>
  </li>
  <li>Selenium Script Login  
  <menu>  
  <li onclick="SyhuntDynamic:DoTargetListAction('seleniumlogin','%i')">Run Test (Headless)</li>  
  <hr>  
  <li onclick="SyhuntDynamic:DoTargetListAction('seleniumloginui','%i')">Run Test (GUI)</li>    
  </menu>  
  </li>  
  <!--li onclick="SyhuntDynamic:DoTargetListAction('manuallogin','%i')">Manual Login (External)...</li-->  
  <hr/>  
  <li onclick="SyhuntDynamic:DoTargetListAction('clearinc','%i')">Clear Incremental Cache</li>  
  <hr/>
  <li onclick="HistView:DeleteURLLogItem('%i','Targets Dynamic')">Delete</li>
  ]]  
 HistView = HistView or Sandcat:require('histview')  
 HistView:ViewURLLogFile(t)
end

function SyhuntDynamic:ViewVulnerabilities()
  local sesname = tab:userdata_get('session','')
  if sesname ~= '' then
      SessionManager:show_sessiondetails(sesname)
  else
    app.showmessage('No session loaded.')
  end
end