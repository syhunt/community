PenTools = extensionpack:new()
PenTools.filename = 'PenTools.scx'
PenTools.msg_restart = 'This change will take effect when you restart the Sandcat Browser.'

function PenTools:init()
 local csmenu = [[
 <!--li onclick="SyCommands:PHPConsole()" style="foreground-image: url(PenTools.scx#images\icon_lang_php.png);"--><!--PHP Console--><!--/li-->
 <li onclick="SyCommands:RubyConsole()" style="foreground-image: url(PenTools.scx#images\icon_lang_ruby.png);">Ruby Console</li>
 ]]
 local pagemenu = [[
 <li onclick="PenTools:PageFind()">Search Source...</li>
 <li onclick="ScriptRunner:vieweditor_js()" style="foreground-image: url(Resources.pak#16\icon_exec.png);">Run JavaScript</li>
 <li onclick="PenTools:ViewPageCookies()">View Cookie</li>
 <li onclick="PenTools:ViewPageHeaders()">View Headers</li>
 <li onclick="PenTools:LoadPageInfoTab('images')" style="foreground-image: url(PenTools.scx#images\icon_image.png);">View Images</li>
 <li onclick="PenTools:Whois(tab.url)">Whois</li>
 ]]
 local extmenu = [[
  <li>Brute Force
   <menu>
   <li onclick="PenTools:CrackMD5()">MD5 Brute Force</li>
   </menu>
  </li>
 ]]
 browser.navbar:addhtml('#csmenu-list',csmenu)
 browser.navbar:inserthtml(5,'#pagemenu-list',pagemenu)
 browser.navbar:inserthtml(2,'#navbarmenu-list',"<li id='tnewcodeedit' style='foreground-image: url(PenTools.scx#images\\icon_codeedit.png);' onclick='CodeEditor:newtab()'>New Editor Tab</li>")
 browser.navbar:inserthtml(0,'#ext-list',extmenu)
 browser.navbar:inserthtmlfile(0,'#toolbar','PenTools.scx#Navbar.html')
 browser.navbar:inserthtmlfile(1,'#searcheng-list','PenTools.scx#Searcheng.html')
 if browser.info.initmode == 'sandcat' then
  browser.tabbar:inserthtml("#newtab",'#tabmenuext',"<li id='tnewcodeedit' style='foreground-image: url(PenTools.scx#images\\icon_codeedit.png);' onclick='CodeEditor:newtab()'>New Editor Tab</li>") 
 end
 self:dofile('Scripts/NirSoft.lua')
 NirSoft:Startup()
end

function PenTools:afterinit()
 browser.addlibinfo('OpenSSL library','file:SSLeay32.dll','The OpenSSL Project','Sandcat:ShowLicense(PenTools.filename,[[Docs\\License_OpenSSL.txt]])')
 browser.addlibinfo('Pascal Script library','3.0.3.57','<a href="#" onclick="browser.newtab([[http://www.RemObjects.com]])">RemObjects Software</a>','Sandcat:ShowLicense(PenTools.filename,[[Docs\\License_PascalScript.txt]])')
 browser.addlibinfo('PHP','5.3.1.0','The PHP Group')
 debug.print('start running')
 self:dofile('Scripts/URLGet.lua')
 self:dofile('Scripts/CodeEditor.lua')
 self:dofile('Scripts/ScriptRunner.lua')
 self:dofile('Scripts/Encoder.lua')
 self:dofile('Commands.lua')
 SyCommands:Add()
 ScriptRunner:start()
end

function PenTools:CrackMD5()
 if MD5CrackPHP == nil then
  self:dofile('Scripts/bruteforce/md5crack.lua')
 end
 MD5CrackPHP:load()
end

function PenTools:EditRequest()
 if XHREditor == nil then
  self:dofile('Scripts/XHREditor.lua')
 end
 XHREditor:load(tab.url)
end

function PenTools:EditRequestLow()
 if ReqEditorLow == nil then
  self:dofile('Scripts/ReqEditorLow.lua')
 end
 ReqEditorLow:vieweditor()
end

function PenTools:PageFind()
  self:dofile('Scripts/SearchSource.lua')
 SearchSource:load()
end

function PenTools:LoadPageInfoTab(name)
 if PageInfo == nil then
  self:dofile('Scripts/PageInfo.lua')
 end
 if name == 'explorer' then
  PageInfo:load()
 end
 if name == 'images' then
  PageInfo:viewimages()
 end
end

function PenTools:ViewRequestLoader()
 if ReqLoader == nil then
  self:dofile('Scripts/ReqLoader.lua')
 end
 ReqLoader:viewloader()
end

function PenTools:NewHTTPRequest()
 require "SelHTTP"
 local c = sel_httprequest:new()
 --if browser.info.proxy == Tor.proxyserver then
  -- Tor is enabled
 -- Tor:ConfigureHTTPClient(c,true)
 --end
 return c
end

function PenTools:OpenWithAgent(navigator)
  if UAChanger == nil then
   self:dofile('Scripts/UAChanger.lua')
  end
  UAChanger:OpenWithAgent(navigator)
end

function PenTools:SetUserAgent(navigator)
  if UAChanger == nil then
   self:dofile('Scripts/UAChanger.lua')
  end
  if navigator == 'Custom' then
   UAChanger:DisplayUserAgentList()
  else
   UAChanger:ApplyUserAgent(navigator)
  end
end

function PenTools:ViewPageCookies()
 if CookieView == nil then
  self:dofile('Scripts/CookieView.lua')
 end
 CookieView:load()
end

function PenTools:ViewCGIScanner()
 if CGIScanner == nil then 
  self:dofile('Scripts/CGIScanner.lua')
 end
 CGIScanner:load()
end

function PenTools:ViewHTTPBruteForce()
 if HTTPAuthForce == nil then
  self:dofile('Scripts/HTTPAuthForce.lua')
 end
 HTTPAuthForce:load()
end

function PenTools:ViewPageHeaders()
 if HeadView == nil then
  self:dofile('Scripts/HeadView.lua')
 end
 HeadView:load()
end

function PenTools:ViewFuzzer()
 if Fuzzer == nil then
  self:dofile('Scripts/Fuzzer.lua')
 end
 Fuzzer:view()
end

function PenTools:ViewFuzzerLow()
 if Fuzzer == nil then
  self:dofile('Scripts/Fuzzer.lua')
 end
 Fuzzer:view_lowlevel()
end

function PenTools:ViewMultiEncoder()
 if MultiEncoder == nil then
  self:dofile('Scripts/EncoderMulti.lua')
 end
 MultiEncoder:viewencoders()
end

function PenTools:ViewUserAgent()
 if UAChanger == nil then
  self:dofile('Scripts/UAChanger.lua')
 end
 UAChanger:DisplayUserAgent()
end

function PenTools:Whois(url)
 if tab:hasloadedurl(true) then
  self:dofile("Scripts/commands/whois.lua")
  browser.setactivepage('log')
  tab.logtext = getwhois(url)
 else
  app.showmessage("No URL loaded.")
 end
end