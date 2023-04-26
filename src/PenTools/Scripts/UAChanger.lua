UAChanger = {}
UAChanger.msg_restart = 'This change will take effect when you restart the Sandcat browser.'

UAChanger.chrome  = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36'
UAChanger.edge    = '' -- must be blank 'Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.10240'
UAChanger.firefox = 'Mozilla/5.0 (Windows NT 5.1; rv:23.0) Gecko/20100101 Firefox/23.0'
UAChanger.ie      = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0)'
UAChanger.opera   = 'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.72 Safari/537.36 OPR/15.0.1147.148'
UAChanger.safari  = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; pt-BR) AppleWebKit/531.22.7 (KHTML, like Gecko) Version/4.0.5 Safari/531.22.7'
-- mobile
UAChanger.android    = 'Mozilla/5.0 (Linux; U; Android 1.1; en-gb; dream) AppleWebKit/525.10+ (KHTML, like Gecko) Version/3.0.4 Mobile Safari/523.12.2 – G1 Phone'
UAChanger.blackberry = 'Mozilla/5.0 (BlackBerry; U; BlackBerry 9800; en) AppleWebKit/534.1+ (KHTML, Like Gecko) Version/6.0.0.141 Mobile Safari/534.1+'
UAChanger.iemobile   = 'HTC_Touch_3G Mozilla/4.0 (compatible; MSIE 6.0; Windows CE; IEMobile 7.11)'
UAChanger.iphone     = 'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543a Safari/419.3'
-- old
--UAChanger.opera1216 = 'Opera/9.80 (Windows NT 5.1) Presto/2.12.388 Version/12.16'
--UAChanger.netscape  = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.12) Gecko/20080219 Firefox/2.0.0.12 Navigator/9.0.0.6'

function UAChanger:ApplyUserAgent(s)
 local ua = self:NameToUserAgent(s)
 self:SetUserAgent(ua)
 if ua ~= '' then
  app.showmessage('User-Agent changed to '..s..': '..ua)
 else
  app.showmessage('User-Agent changed to default (Edge)')
 end
  app.showmessage(UAChanger.msg_restart)
end

function UAChanger:ApplyCustomUserAgent()
 local ui = self.ui
 self:SetUserAgent(ui.customuseragent.value)
 app.showmessage('User-Agent changed to custom: '..ui.customuseragent.value)
 app.showmessage(self.msg_restart)
end

function UAChanger:DisplayUserAgent()
 --tab:runluaonlog('"done"','UAChanger:ShowAgent()')
 --tab:runjs("results={};results.ua=navigator.userAgent;window.chrome.webview.postMessage(results);window.chrome.webview.postMessage('done');")
 tab:runluaafterjs('UAChanger:ShowAgent()','results={};results.ua=navigator.userAgent;JSON.stringify(results)')
end

function UAChanger:DisplayUserAgentList()
 local html = [[
  <table width="100%" style="height:*;"><tr>
  <td width="94%" valign="top">
  <input type="text" id="customuseragent" style="width:100%;height:*;"></plaintext>
  <select id="useragentlist" size="5" style="width:100%;" size=10 onchange="UAChanger:UpdateCustomUserAgent()">
  ]]..self:GetUserAgentList()..[[
  </select>
  </td>
  <td width="1%"></td>
  <td width="5%" valign="top">
  <button id="apply" onclick="UAChanger:ApplyCustomUserAgent()">Apply</button>
  </td>
  </tr></table>
 ]]
  browser.loadpagex({name='uachanger', html=html,table='UAChanger.ui'})
end

function UAChanger:GetUserAgentList()
 local p = ctk.string.loop:new()
 local flist = ctk.string.list:new()
 local l = PenTools:getfile('Scripts/Agent.lst')
 p:load(l)
 while p:parsing() do
  flist:add('<option>'..p.current..'</option>')
 end
 local result = flist.text
 flist:release()
 p:release()
 return result
end

function UAChanger:NameToUserAgent(s)
 local ua = ''
 if s == 'Android' then ua = self.android end
 if s == 'BlackBerry' then ua = self.blackberry end
 if s == 'Chrome' then ua = self.chrome end
 if s == 'Edge' then ua = self.edge end
 if s == 'Opera' then ua = self.opera end
 if s == 'Firefox' then ua = self.firefox end
 if s == 'IE' then ua = self.ie end
 if s == 'IEMobile' then ua = self.iemobile end
 if s == 'iPhone' then ua = self.iphone end
 if s == 'Safari' then ua = self.safari end
 return ua
end

function UAChanger:OpenWithAgent(s)
 local backup = browser.info.useragent
 local ua = self:NameToUserAgent(s)
 self:SetUserAgent(ua)
 prefs.save()
 browser.newwindow(tab.url)
 -- restores user agent
 ctk.utils.delay(1000)
 self:SetUserAgent(backup)
 prefs.save()
end

function UAChanger:SetUserAgent(agent)
 prefs.set('sandcat.browser.useragent',agent)
end

function UAChanger:ShowAgent()
 local agent = tab.lastjsexecresult
 local j = ctk.json.object:new()
 j:load(agent)
 agent = ctk.html.escape(j.ua)
 j:release()
 app.showmessagex('Your current User-Agent is:<br><br><b>'..agent..'</b>')
end

function UAChanger:UpdateCustomUserAgent()
 local ui = self.ui
 ui.customuseragent.value = ui.useragentlist.value
end