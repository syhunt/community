CGIScanner = {}

function CGIScanner:load()
 local html = PenTools:getfile('Scripts/CGIScanner.html')
 browser.loadpagex('cgiscanner',html,'CGIScanner.ui')
 local ui = self.ui
 ui.url.value = tab.url
end

function CGIScanner:start()
 local ui = self.ui
 local script = PenTools:getfile('Scripts/CGIScannerTask.lua')
 local j = ctk.json.object:new()
 j.pathlistfile = ui.pathlist.value
 if ctk.file.exists(j.pathlistfile) then
  j.method = ui.method.value
  j.url = ui.url.value
  tab:runtask(script,tostring(j))
  browser.options.showheaders = true
 end
 j:release()
end