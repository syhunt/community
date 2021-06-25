ScanScheduler = {
 title = 'Scan Scheduler'
}

-- Returns the name of the app associated with tracker (Jira, GitHub, etc)
function ScanScheduler:GetScheduledScan(name)
  local jsonfile = symini.info.configdir..'\\Scheduler\\'..name..'.json'
  local j = ctk.json.object:new()
  local app = ''
  j:loadfromfile(jsonfile)
  app = j['tracker.defaultapp']
  j:release()
  return app
end

function ScanScheduler:EditSchedulePreferences(name)
  local jsonfile = symini.info.configdir..'\\Scheduler\\'..name..'.json'
  local slp = ctk.string.loop:new()
  local hs = symini.hybrid:new()
  hs:start()
  slp:load(hs.options)
  while slp:parsing() do
    prefs.regdefault(slp.current,hs:prefs_getdefault(slp.current))
  end
  local t = {}
  t.html = SyHybrid:getfile('hybrid/prefs_scheduler/prefs.html')
  t.html = ctk.string.replace(t.html,'%dynamic_targets%',SyhuntDynamic:GetTargetListHTML())
  t.html = ctk.string.replace(t.html,'%code_targets%',SyhuntCode:GetTargetListHTML())
  t.html = ctk.string.replace(t.html,'%email_trackers%',TrackerManager:gettrackeroptionlist('EMAIL'))
  t.id = 'syhuntschedulerprefs'
  t.options = hs.options
  t.jsonfile = jsonfile
  hs:release()
  slp:release()  
  return Sandcat.Preferences:EditCustomFile(t)
end

function ScanScheduler:EditScheduleTargetPreferences(name)
  local res = symini.scheduler_getscheduledscandetails(name)
  if res.success == true then  
    if res.target_type == 'url' then
      SyhuntDynamic:EditSitePreferences(res.target_url)
    else
      app.showmessage('Target preferences not supported for this type of target.')
    end
  else
    app.showmessage('Failed! '..res.errormsg)
  end
end

function ScanScheduler:ShowScheduledScanCommandLine(name, action)
  action = action or "show"
  local hs = symini.hybrid:new()
  hs:start()
  local res = hs:scheduler_getscheduledscancmdln(name)
    if res.success == true then
      if action == 'show' then
        app.showalerttext(res.filename..' '..res.params)
      elseif action == 'copyfilename' then
        ctk.utils.clipboard_settext(res.filename)
      elseif action == 'copyfilenamenparams' then
        local sl = ctk.string.list:new()
        sl:add('Filename: '..res.filename)
        sl:add('Parameters: '..res.params)
        ctk.utils.clipboard_settext(sl.text)
        sl:release()
      elseif action == 'copyparams' then
        ctk.utils.clipboard_settext(res.params)
      end
    else
      app.showmessage('Failed! '..res.errormsg)
    end
  hs:release()
end

function ScanScheduler:TestScheduledScan(name, visible)
  local hs = symini.hybrid:new()
  hs:start()
  local res = hs:scheduler_runscheduledscan(name, visible)
  if res.success == false then
    app.showmessage('Failed! '..res.errormsg)
  end
  hs:release()
end

function ScanScheduler:AddScheduledScan()
  if SyHybridUser:IsOptionAvailable(true) == true then
      local item  = {}
      item.name = symini.getsessionname()
      item.url = ctk.convert.strtohex(item.name)
      local ok = self:EditSchedulePreferences(item.name)
      if ok == true then
        HistView:AddURLLogItem(item, symini.info.schedlistname)
        symini.scheduler_sendsignal('update')
        self:ViewScheduledScans(false)
      end
  end
end

function ScanScheduler:ClearIncrementalData(name)
  local hs = symini.hybrid:new()
  hs:start()
  local res = hs:scheduler_getscheduledscancmdln(name)
  if res.success == true then
    SyhuntDynamic:ClearIncrementalData(res.inctag)
  else
    app.showmessage('Failed! '..res.errormsg)
  end
  hs:release()   
end

function ScanScheduler:DoSchedulerAction(action, itemid)
  local item = HistView:GetURLLogItem(itemid, symini.info.schedlistname)
  if item ~= nil then
    if action == 'clearinc' then
      self:ClearIncrementalData(item.name)
    end
    if action == 'editprefs' then
      local ok = self:EditSchedulePreferences(item.name)
      if ok == true then
        symini.scheduler_sendsignal('update')
        self:ViewScheduledScans(false)
      end
    end
    if action == 'editsiteprefs' then
      self:EditScheduleTargetPreferences(item.name)
    end    
    if action == 'showcmdln' then
      self:ShowScheduledScanCommandLine(item.name)
    end
    if action == 'copycmdln_filenamenparams' then
      self:ShowScheduledScanCommandLine(item.name, 'copyfilenamenparams')
    end
    if action == 'copycmdln_filename' then
      self:ShowScheduledScanCommandLine(item.name, 'copyfilename')
    end
    if action == 'copycmdln_params' then
      self:ShowScheduledScanCommandLine(item.name, 'copyparams')
    end    
    if action == 'test' then
      self:TestScheduledScan(item.name, true)
    end
    if action == 'testhidden' then
      self:TestScheduledScan(item.name, false)
    end    
    if action == 'delete' then
      HistView:DeleteURLLogItem(itemid,symini.info.schedlistname)
      local jsonfile = symini.info.configdir..'\\Scheduler\\'..item.name..'.json'
      ctk.file.delete(jsonfile)
      self:ViewScheduledScans(false)
    end
  end
end

function ScanScheduler:GetScheduledScansList()
  HistView = HistView or Sandcat:require('histview')  
  return HistView:GetURLLogLists(symini.info.schedlistname).idlist
end

function ScanScheduler.GenSchedDescription(t)
  local desc = symini.getscheduledscandesc(t.name)
  desc = ctk.html.escape(desc)
  return desc
end

function ScanScheduler:GetScheduledScanIcons(d)
  local icons = {}
  icons.target = 'Resources.pak#16/icon_blank.png'
  icons.box = 'Resources.pak#16/icon_blank.png'  
  if d.target_type == 'urlgit' then icons.target = 'SyHybrid.scx#images/16/code_bookmarks_url.png' end
  if d.target_type == 'url' then icons.target = 'SyHybrid.scx#images/16/dynamic_bookmark.png' end
  if d.target_type == 'dir' then icons.target = 'SyHybrid.scx#images/16/folder_blue2.png' end
  if ctk.string.endswith(d.target_urlgit,'.git') == true then icons.target = 'SyHybrid.scx#images/16/code_bookmarks_git.png' end
  if d.huntmethod_box == 'white' then icons.box = 'SyHybrid.scx#images/16/box_white.png' end
  if d.huntmethod_box == 'black' then icons.box = 'SyHybrid.scx#images/16/box_black.png' end
  if d.huntmethod_box == 'gray' then icons.box = 'SyHybrid.scx#images/16/box_gray.png' end  
  return icons
end

function ScanScheduler:IncludeScheduledScanItem(tb, schedid)
  local schedname = HistView:GetURLLogItem(schedid, symini.info.schedlistname).name
  local d = symini.scheduler_getscheduledscandetails(schedname)
  local icons = self:GetScheduledScanIcons(d)
  local title = d.name
  if d.name == '' then
    if ctk.string.matchx(schedname, '#*-*#') == true then
    title = 'Untitled: '..schedname
    else
    title = schedname
    end
  end
  local menu =  [[
  <menu.context id="menu%i">
  <li onclick="ScanScheduler:DoSchedulerAction('editprefs','%i')">Edit Schedule Preferences...</li>
  <hr/>
  <li onclick="ScanScheduler:DoSchedulerAction('editsiteprefs','%i')">Edit Assigned Target Preferences...</li>
  <hr/>
  <li onclick="ScanScheduler:DoSchedulerAction('test','%i')">Run Test Scan</li>  
  <hr/>  
  <li onclick="ScanScheduler:DoSchedulerAction('testhidden','%i')">Run Test Scan in Background</li>  
  <li>CLI Parameters
   <menu>
   <li onclick="ScanScheduler:DoSchedulerAction('copycmdln_filenamenparams','%i')">Copy Filename & Parameters</li>  
   <li onclick="ScanScheduler:DoSchedulerAction('copycmdln_filename','%i')">Copy Filename</li>  
   <li onclick="ScanScheduler:DoSchedulerAction('copycmdln_params','%i')">Copy Parameters</li>
   <hr/>
   <li onclick="ScanScheduler:DoSchedulerAction('showcmdln','%i')">Show Command Line</li>
   </menu>
  </li>
  <hr/>
  <li onclick="ScanScheduler:DoSchedulerAction('clearinc','%i')">Clear Incremental Cache</li>    
  <hr/>
  <li onclick="ScanScheduler:DoSchedulerAction('delete','%i')">Delete</li>
  </menu>
  ]]  
  local troption = '<tr role="option" style="context-menu: selector(#menu%i);" ondblclick="ScanScheduler:DoSchedulerAction([[editprefs]],[[%i]])">'
  troption = ctk.string.replace(troption, '%i', schedid)
  tb:add(troption)
  tb:add('<td>'..ctk.html.escape(title)..'</td>')
  tb:add('<td>'..ctk.html.escape(d.description)..'</td>')  
  tb:add('<td><img .lvfileicon src="'..icons.target..'"> '..ctk.html.escape(d.target_description)..'</td>')  
  tb:add('<td><img .lvfileicon src="'..icons.box..'"> '..d.target_type_short..' ('..d.huntmethod..')</td><td>'..d.chron_lastruntime..'</td>')    
  tb:add('</tr>')
  menu = ctk.string.replace(menu, '%i', schedid)
  tb:add(menu)
end

function ScanScheduler:ViewScheduledScans(newtab)
 local html = SyHybrid:getfile('hybrid/scheduler/list.html')
 local tb = ctk.string.list:new()
 local lp = ctk.string.loop:new()
 lp:load(self:GetScheduledScansList())
 while lp:parsing() do
   self:IncludeScheduledScanItem(tb, lp.current)
 end 
 html = ctk.string.replace(html, '%scheduledscans%', tb.text)
 
 local t = {}
 t.title = 'Scheduled Scans'
 t.toolbar = 'SyHybrid.scx#hybrid/scheduler/toolbar.html'
 --t.histname = symini.info.schedlistname
 t.icon = 'url(SyHybrid.scx#images\\16\\date_task.png);'
 t.html = html
 t.tag = 'scheduler'
 if newtab == false then
   symini.scheduler_sendsignal('start')
   tab:loadx(html)
 else
   browser.newtabx(t)
 end
 tb:release()
 lp:release() 
end

function ScanScheduler:NewScanDialog()
 self:ViewScheduledScans()
 self:AddScheduledScan()
end