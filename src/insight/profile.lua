AttackerProfile = {}
AttackerProfile.uitable = 'AttackerProfile.ui'

function AttackerProfile:ReconstructSession(ip)
  local ui = self.ui
  local huntmethod = 'reconstruct'
  if ui.recasnew.value == true then
    huntmethod = 'normal'
  end
  local filename = SyhuntInsight.ui.file.value
  if SyhuntInsight:NewTab() ~= '' then
    SyhuntInsight:ScanFile(filename,huntmethod,ip)
  end
end

function AttackerProfile:load(ip)
  local tipak = extensionpack:new()
  tipak.filename = 'ToolInfo.pak'
  local toolline = [[<option.link style="foreground-image:url(ToolInfo.pak#icons\32\%s.png)">%s</option>]]
  local platline = [[<img style="width:16px;height:16px;foreground-image:url(ToolInfo.pak#icons\16\%s.png)" alt="%s">]]
  debug.print('Loading attacker profile: '..ip)
  self.page = SyHybrid:getfile('insight/profile.html')
  local geodb = require "mmdb".open(app.dir.."Packs\\GeoLite2\\GeoLite2-Country.mmdb")
  local ipcountry = {}
  if string.match(ip,'[:]') then
    ipcountry = geodb:search_ipv6(ip)
  else
    ipcountry = geodb:search_ipv4(ip)
  end
  
  local i = symini.insight:new()
  local json = i:getprofile(ip)
 
  local j = slx.json.object:new()
  j:load(json)
  local html = self.page
  local toollist = ''
  local platlist = ''
  local teclist = ''
  local slp = slx.string.loop:new()
  slp:load(j.tools)
  while slp:parsing() do
    if slp.current ~= '' then
      toolinfo = i:gettoolinfo(slp.current)
      icon = slp.current
      if tipak:fileexists('icons/32/'..icon..'.png') == false then
        icon = 'unknown'
      end
      toollist = toollist..string.format(toolline,icon,toolinfo.title)
    end
  end
  slp:load(j.platforms)
  while slp:parsing() do
    if slp.current ~= '' then
      toolinfo = i:gettoolinfo(slp.current)
      icon = slp.current
      if tipak:fileexists('icons/16/'..icon..'.png') == false then
        icon = 'unknown'
      end
      platlist = platlist..string.format(platline,icon,toolinfo.title)
    end
  end
  if platlist == '' then
    platlist = 'Unknown'
  end
  slp:load(j.techniques)
  while slp:parsing() do
    if slp.current ~= '' then
      teclist = teclist..string.format('<option>%s</option>',slx.html.escape(slp.current))
    end
  end
  html = slx.string.replace(html, '%ip%',ip)
  html = slx.string.replace(html, '%toollist%',toollist)
  html = slx.string.replace(html, '%platforms%',tostring(platlist))
  html = slx.string.replace(html, '%atkcount%',tostring(j.attackcount))
  html = slx.string.replace(html, '%teccount%',tostring(j.techniques_count))
  html = slx.string.replace(html, '%toolcount%',tostring(j.tools_count))
  html = slx.string.replace(html, '%country%',ipcountry.country.names.en)
  html = slx.string.replace(html, '%cniso%',string.lower(ipcountry.country.iso_code))
  html = slx.string.replace(html, '%techniques%',teclist)
  browser.bottombar:loadx(html,self.uitable)
  local ui = self.ui
  j:release()
  slp:release()
  i:release()
  tipak:release()
end