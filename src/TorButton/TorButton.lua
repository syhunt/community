TorButton = extensionpack:new()
TorButton.filename = 'TorButton.scx'

function TorButton:init()
 self:dofile('Tor.lua')
 Tor:Startup()
end

function TorButton:afterinit()
 browser.addlibinfo('Tor','3.6.2','The Tor Project, Inc.','Sandcat:ShowLicense(TorButton.filename,[[docs\\License_Tor.txt]])')
end

function TorButton:shutdown()
 if Tor ~= nil then
  Tor:Shutdown()
 end
end