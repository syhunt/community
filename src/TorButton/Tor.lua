Tor = {}

Tor.socks = {}
Tor.socks.server = '127.0.0.1'
Tor.socks.port = 9050
Tor.socks.level = '5'

Tor.executable = 'tor.exe'
Tor.checkurl = 'http://check.torproject.org/'
Tor.proxyserver = 'socks'..Tor.socks.level..'://'..Tor.socks.server..':'..Tor.socks.port
Tor.msgenabled = 'Tor Proxy Enabled.\n\nChromium plugin support disabled for greater anonymity.'
Tor.msgdisabled = 'Tor Proxy Disabled.\n\nChromium plugin support re-enabled.'
Tor.msgpartialanon = 'Warning: Tor Proxy is disabled for web browsing.\n\nThe request will be sent via Tor network, but the response will be rendered using your normal connection.'

function Tor:Check()
 tab:gotourl(self.checkurl)
end

function Tor:AddButton()
 browser.navbar:inserthtmlfile('#extensions','#toolbar',TorButton.filename..'#Tor.html')
 browser.navbar:addtiscript([[
 type TorButton
 {
  function SetIcon(state) {
   var torbtn = $("#torbutton");
   if (torbtn != undefined) {
    torbtn.style["foreground-image"] = state;
   }
  }
  function Enable()  { TorButton.SetIcon("@ICON_TOR_ENABLED"); }
  function Disable() { TorButton.SetIcon("@ICON_TOR_DISABLED"); }
 }

 Sandcat.RunLuaQ("Tor:UpdateIcon()");
 ]])
end

function Tor:UpdateIcon()
 if self:IsRunning() then
  if browser.info.proxy == self.proxyserver then
  browser.navbar:eval('TorButton.Enable()')
  else
  browser.navbar:eval('TorButton.Disable()')
  end
 else
  browser.navbar:eval('TorButton.Disable()')
 end
end

function Tor:SetProxy(proxy)
 local proxykey = 'sandcat.browser.proxy.server'
 local anonkey = 'sandcat.browser.proxy.anonymize'
 if proxy == 'Tor' then
  prefs.set(anonkey,true)
  prefs.set(proxykey,self.proxyserver)
  app.showmessage(self.msgenabled)
  browser.navbar:eval('TorButton.Enable();')
 else 
  prefs.set(anonkey,false)
  prefs.set(proxykey,'')
  app.showmessage(self.msgdisabled)
  browser.navbar:eval('TorButton.Disable();')
 end
 prefs.save()
 app.showmessage('Please restart the Sandcat browser before attempting to navigate.')
end

function Tor:ConfigureHTTPClient(client,enabletor)
 if enabletor == true then
   client:setsocks(Tor.socks)
 else
   client.useproxy = false
 end
end

function Tor:IsRunning()
 return slx.task.isrunning(self.executable)
end

function Tor:Run()
  if slx.task.isrunning(self.executable) == false then
   slx.file.exechide(app.dir..'Extensions\\Tor\\'..self.executable,'',app.dir)
  end
end

function Tor:Startup()
 if browser.info.proxy == self.proxyserver then
  Tor:Run()
 end
 Tor:AddButton()
end

function Tor:Shutdown()
  if slx.task.isrunning(self.executable) == true then
   slx.task.kill(self.executable)
  end
end