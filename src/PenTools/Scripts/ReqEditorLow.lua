ReqEditorLow = {}

function ReqEditorLow:load(req,head)
  --local tor_running = Tor:IsRunning()
  local html = PenTools:getfile('Scripts/ReqEditorLow.html')
  browser.loadpagex({name='request editor (low)', html=html,table='ReqEditorLow.ui'})
  local ui = self.ui
  self:loadhost()
  if req == '' then
   req = 'GET /'..ctk.url.crack(tab.url).path..' HTTP/1.1\nHost: '..ui.host.value..'\nConnection: Keep-Alive'
  end
  ui.request.value = req
  ui.header.value = head
  --if tor_running == true then
  -- ui.viator.value = true
  -- ui.viator:setstyle('visibility','visible')
  --else
   ui.viator:setstyle('visibility','hidden')
  --end
end

function ReqEditorLow:loadhost()
  local ui = self.ui
  local url = ctk.url.crack(tab.url)
  local request = ui.request.value..'\n\n'
  if ctk.http.getheader(request,'Host') ~= '' then
   url.host = ctk.http.getheader(request,'Host')
   url.host = ctk.string.trim(url.host)
   url.port = 80
   if ctk.string.match(url.host,'*:*') then
    url.port = ctk.string.after(url.host,':')
    url.host = stringring.before(url.host,':')
   end
  end
  ui.host.value = url.host
  ui.port.value = url.port
end

function ReqEditorLow:loadinfuzzer()
  local baserequest = self.ui.request.value
  if Fuzzer == nil then
   PenTools:dofile('Scripts/Fuzzer.lua')
  end
  Fuzzer:view_lowlevel()
  Fuzzer.ui.request.value = ctk.string.replace(baserequest,' HTTP/','{$1} HTTP/')
end

function ReqEditorLow:sendrequest()
  browser.options.showheaders = true
  local ui = self.ui
  if ui.request.value ~= '' then
   local http = PenTools:NewHTTPRequest()
   local host = ui.host.value
   local port = ui.port.value
   local request = ui.request.value..'\n\n'
   http.description = 'Direct Request (Low-Level)'
   ui.sendrequestlow.enabled = false
   --[[
   if ui.viator.value == true then
    http.description = 'Direct Request (Low; Via Tor)'
    Tor:ConfigureHTTPClient(http,true)
   else
    Tor:ConfigureHTTPClient(http,false)
   end
   --]]
   http.autolength = true
   http:openlow(host,port,request)
   ui.request.value = request
   ui.header.value = http:getheader()
   --local newpath = ctk.http.crackrequest(request).path
   --local newurl = ctk.url.genfromhost(host,port)..newpath
   tab:logrequest(http.requestinfo)
   --if ui.render.value == true then
   --tab:gotourl(newurl,http.text)
   --end
   http:release()
   ui.sendrequestlow.enabled = true
  else
   app.showmessage('Request is empty!')
  end
end

function ReqEditorLow:vieweditor()
 self:load(tab.sentheaders,tab.rcvdheaders)
end