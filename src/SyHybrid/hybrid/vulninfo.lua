VulnInfo = {}
VulnInfo.uitable = 'VulnInfo.ui'

function VulnInfo:replayattack(v)
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
  require "SyCVSS"
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
  ui.cvss3score.value = cvssutils.cvss3_vectortoscore(t.ref_cvss3_vector).basescoreseverity
  ui.cvss3vector.value = ' ('..t.ref_cvss3_vector..')'
end