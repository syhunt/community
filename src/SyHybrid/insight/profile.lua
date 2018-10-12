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
  local icon = ''
  local tipak = extensionpack:new()
  tipak.filename = 'ToolInfo.pak'
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
  local prof = i:getprofile(ip)
  local j = ctk.json.object:new()
  j:load(prof)
  local html = self.page
  local slp = ctk.string.loop:new()
  browser.loadpagex({
    name='attacker profile',
    html=html,
    table=self.uitable,
    noreload=true
    }
   )
  browser.pagex:eval('ClearProfile();')
  local ui = self.ui
  ui.iptext.value = ip
  ui.atkcount.value = tostring(j.attackcount)
  ui.teccount.value = tostring(j.techniques_count)
  ui.toolcount.value = tostring(j.tools_count)
  if ipcountry ~= nil then
    ui.country.value = ipcountry.country.names.en
    icon = 'flags.pak#16\\'..string.lower(ipcountry.country.iso_code)..'.png'
  else
    ui.country.value = 'N/A'
    icon = 'resources.pak#16\\icon_blank.png'
  end
  ui.countryflag:setattrib('src', icon)
  
  slp:load(j.tools)
  while slp:parsing() do
    if slp.current ~= '' then
      toolinfo = i:gettoolinfo(slp.current)
      icon = slp.current
      if tipak:fileexists('icons/32/'..icon..'.png') == false then
        icon = 'unknown'
      end
      local tool = ctk.json.object:new()
      tool.icon = icon
      tool.title = toolinfo.title
      browser.pagex:eval('AddTool('..tool:getjson_unquoted()..');')
      tool:release()
    end
  end
  
  slp:load(j.techniques)
  while slp:parsing() do
    if slp.current ~= '' then
      browser.pagex:eval('AddTechnique("'..ctk.html.escape(slp.current)..'");')
    end
  end
  
  local foundplat = false
  ui.platdesc.value = ''
  slp:load(j.platforms)
  while slp:parsing() do
    if slp.current ~= '' then
      toolinfo = i:gettoolinfo(slp.current)
      icon = slp.current
      if tipak:fileexists('icons/16/'..icon..'.png') == false then
        icon = 'unknown'
      end
      foundplat = true
      local plat = ctk.json.object:new()
      plat.icon = icon
      plat.title = toolinfo.title
      browser.pagex:eval('AddPlatform('..plat:getjson_unquoted()..');')
      plat:release()
    end
  end
  if foundplat == false then
    ui.platdesc.value = 'Unknown'
  end
  
  j:release()
  slp:release()
  i:release()
  tipak:release()
end