NirSoft = {}

function NirSoft:Startup()
 local cachebuttons = [[
 <button #btnviewcache onclick="NirSoft:LaunchCacheView()">View Cache</button>
 <button #btnviewcookies onclick="NirSoft:LaunchCookiesView()">View Cookies</button>&nbsp;
 ]]
 browser.inserthtml('dlg.prefs',-1,'#cachebuttons',cachebuttons)
 browser.navbar:inserthtml('#tcache','#navbarmenu-list','<li onclick="NirSoft:LaunchCookiesView()" style="foreground-image: url(PenTools.scx#images/icon_cookiesview.png);">Cookies</li>')
 browser.navbar:inserthtml(-1,'#tcachemenu','<li onclick="NirSoft:LaunchCacheView()" style="foreground-image: url(PenTools.scx#images/icon_cacheview.png);">HTTP Cache</li><hr/>')
 browser.addlibinfo('ChromeCacheView','file:Extensions\\ChromeCacheView\\ChromeCacheView.exe','Nir Sofer')
 browser.addlibinfo('ChromeCookiesView','file:Extensions\\ChromeCookiesView\\ChromeCookiesView.exe','Nir Sofer')
end

function NirSoft:LaunchCacheView()
 local ccvdir = app.dir..'Extensions\\ChromeCacheView\\'
 local cfgfile = browser.info.cachedir..'ChromeCacheView.cfg'
 if ctk.file.exists(cfgfile) == false then
  local c = ctk.string.list:new()
  c:add('[General]')
  c:add('RememberFolder=1')
  c:add('CacheFolder='..browser.info.cachedir..'Cache') 
  c:savetofile(cfgfile)
  c:release()
 end
 ctk.file.exec(ccvdir..'ChromeCacheView.exe','',browser.info.cachedir)
end

function NirSoft:LaunchCookiesView()
 local ccvdir = app.dir..'Extensions\\ChromeCookiesView\\'
 local cfgfile = browser.info.cachedir..'ChromeCookiesView.cfg'
 if ctk.file.exists(cfgfile) == false then
  local c = ctk.string.list:new()
  c:add('[General]')
  c:add('LoadCookiesFileOnStart=1')
  c:add('CookiesFile='..browser.info.cachedir..'Cookies') 
  c:savetofile(cfgfile)
  c:release()
 end
 ctk.file.exec(ccvdir..'ChromeCookiesView.exe','',browser.info.cachedir)
end