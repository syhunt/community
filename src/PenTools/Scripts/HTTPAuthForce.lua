HTTPAuthForce = {}

function HTTPAuthForce:load()
 local html = PenTools:getfile('Scripts/HTTPAuthForce.html')
 browser.loadpagex('authforce',html,'HTTPAuthForce.ui')
 local ui = self.ui
 ui.url.value = tab.url
end

function HTTPAuthForce:start()
 local ui = self.ui
 local script = PenTools:getfile('Scripts/HTTPAuthForceTask.lua')
 local j = slx.json.object:new()
 j.userlistfile = ui.userlist.value
 j.passlistfile = ui.passlist.value
 if slx.file.exists(j.userlistfile) then
  if slx.file.exists(j.passlistfile) then
   j.method = ui.method.value
   j.url = ui.url.value
   tab:runtask(script,tostring(j))
   browser.options.showheaders = true
  end
 end
 j:release()
end