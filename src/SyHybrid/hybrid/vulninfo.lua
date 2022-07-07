VulnInfo = {}
VulnInfo.uitable = 'VulnInfo.ui'

function VulnInfo:getvulndetails(jsonfile)
  local vuln = {}
  local ses = symini.session:new()
  ses.name = tab:userdata_get('session')
  vuln = ses:getvulndetails(jsonfile)
  ses:release()
  return vuln
end

function VulnInfo:editvulnfile_custom(jsonfile,htmlfile)
  local vuln = self:getvulndetails(jsonfile)
  local cvss3score = syutils.cvss3_vectortoscore(vuln.ref_cvss3_vector).basescoreseverity
  local cvss2score = syutils.cvss2_vectortoscore(vuln.ref_cvss2_vector).basescoreseverity
  local sumpassleak = symini.icy_summaryzepassleak(vuln.exfilpwfile)
  local sumfileleak = symini.icy_summaryzefileleak(vuln.exfilleakfile)
  local slp = ctk.string.loop:new()
  local hs = symini.hybrid:new()
  hs:start()
  slp:load(hs.options_vuln)
  while slp:parsing() do
    prefs.regdefault(slp.current,hs:vuln_getdefault(slp.current))
  end
  local extbtns = ''
  if vuln.request ~= '' then
    extbtns = '<button #replay style="width:50px;margin-right:5px;">Replay Request</button>'
  end
  
  local t = {}
  t.html = SyHybrid:getfile(htmlfile)
  t.html = ctk.string.replace(t.html,'%vulnfilename%', ctk.html.escape(vuln.filename))  
  t.html = ctk.string.replace(t.html,'%response%', ctk.html.escape(vuln.response))  
  t.html = ctk.string.replace(t.html,'%request_header%', ctk.html.escape(vuln.request))  
  t.html = ctk.string.replace(t.html,'%response_header%', ctk.html.escape(vuln.responseheader))
  t.html = ctk.string.replace(t.html,'%exfil_data%', ctk.html.escape(vuln.exfildata))  
  t.html = ctk.string.replace(t.html,'%exfil_passwords%', sumpassleak.resulthtml)  
  t.html = ctk.string.replace(t.html,'%exfil_passwords_notice%', sumpassleak.resultdesc)  
  t.html = ctk.string.replace(t.html,'%exfil_files%', sumfileleak.resulthtml) 
  t.html = ctk.string.replace(t.html,'%exfil_files_notice%', sumfileleak.resultdesc)     
  t.html = ctk.string.replace(t.html,'%source_code%', ctk.html.escape(vuln.appsource))
  t.html = ctk.string.replace(t.html,'%cvss3_score%', cvss3score)
  t.html = ctk.string.replace(t.html,'%cvss2_score%', cvss2score)
  t.html = ctk.string.replace(t.html,'<!--%extra_buttons%-->', extbtns)  
  t.id = 'syhuntvulnprefs'
  t.options = hs.options_vuln
  t.jsonfile = vuln.filename
  Sandcat.Preferences:EditCustomFile(t)
  hs:release()
  slp:release()
end

function VulnInfo:editvulnfile(jsonfile)
  local scanmod = self:getvulndetails(jsonfile).checkmodule
  if scanmod == 'breachscanner' then
    self:editvulnfile_custom(jsonfile, 'icy/prefs_leak/prefs.html')
  else
    self:editvulnfile_custom(jsonfile, 'hybrid/prefs_vuln/prefs.html')
  end
end

function VulnInfo:loadvulnfile(jsonfile)
  local v = self:getvulndetails(jsonfile)
  self:load(v)
end

function VulnInfo:replayattack(jsonfile)
  local v = self:getvulndetails(jsonfile)
  browser.options.showheaders = true
  if v.request ~= '' then
   local http = PenTools:NewHTTPRequest()
   local host = v.host
   local port = v.port
   local request = v.request
   http.description = 'Attack Replay (Low-Level)'
   http.autolength = true
   http:openlow(host,port,request)
   tab:logrequest(http.requestinfo)
   http:release()
  else
   app.showmessage('Request is empty!')
  end
end

function VulnInfo:gettrackerbuttons()
 local slp = ctk.string.loop:new()
 slp:load(TrackerManager:GetIssueTrackerList())
 local btns = ''
 while slp:parsing() do
  local tracker_hex = ctk.convert.strtohex(slp.current)
  local tracker_escaped = ctk.html.escape(slp.current)
  local app = TrackerManager:GetTrackerApp(slp.current)
  app = ctk.html.escape(app:upper())
  btns = btns..'<widget .tb-button onclick="TrackerManager:SubmitIssue_FromVulnFile(ctk.convert.hextostr([['..tracker_hex..']]),VulnInfo.ui.vulnfilename.value)" title="Send Issue To Tracker: '..tracker_escaped..' ('..app..')"><img style="foreground-image: url(SyHybrid.scx#images\\16\\bug_alt.png);" /></widget>'
 end
 slp:release()
 return btns
end

function VulnInfo:load(t)
  debug.print('Loading vuln info...')
  self.vuln = t
  self.page = SyHybrid:getfile('hybrid/vulninfo.html')
  local pset = {}
  pset.html = self.page
  pset.html = ctk.string.replace(pset.html,'%issue_trackers%',self:gettrackerbuttons())
  pset.name = 'vulnerability info'
  pset.table = self.uitable
  pset.noreload = true
  browser.loadpagex(pset)
  local ui = self.ui
  ui.vulnfilename.value = t.filename
  ui.checkname.value = t.checkname
  ui.risk.value = t.risk
  ui.locationtext.value = t.location
  if t.locationsrc ~= '' then
    ui.locationtext.value = t.locationsrc
  end
  ui.matchedsig.value = t.matchedsig
  ui.rt_description.value = t.description
  ui.rt_solution.value = t.recommendations
  ui.rt_vulncode.value = t.vulncode
  ui.checklog.value = t.checklog
  ui.cvss3score.value = syutils.cvss3_vectortoscore(t.ref_cvss3_vector).basescoreseverity
  ui.cvss3vector.value = ' ('..t.ref_cvss3_vector..')'
end