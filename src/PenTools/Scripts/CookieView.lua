CookieView = {}

function CookieView:display()
  local cktable = ''
  local cookie = tab.lastjsexecresult --tab.lastjslogmsg
  local j = ctk.json.object:new()
  j:load(cookie)
  cookie = j.cookie
  j:release()
  cookie = ctk.string.replace(cookie,'; ','\n')
  if cookie ~= '' then
   cktable = '<table border=1 width="100%"><tr style="color:gray;"><td>Cookie</td><td>Value</td></tr>'
   p = ctk.string.loop:new()
   p:load(cookie)
   while p:parsing() do
    local ckname = ctk.html.escape(ctk.string.before(p.current,'='))
    local ckvalue = ctk.html.escape(ctk.string.after(p.current,'='))
    cktable = cktable..'<tr><td width="15%"><b>'..ckname..'</b></td><td width="85%"><input type="text" style="width:*;" value="'..ckvalue..'" readonly="true"></td></tr>'
   end
   p:release()
   cktable = cktable..'</table>'
  else
   cktable = '<b>No cookies found.</b>'
  end
  local html = [[
  <table width="100%" height="100%"><tr>
  <td width="95%" valign="top">]]..cktable..[[</td>
  <td width="5%" valign="top"><button onclick="CookieView:load()">Refresh</button></td>
  </tr></table>
  ]]
  --browser.bottombar:loadx(html)
  browser.loadpagex({name='cookieview', html=html})
end

function CookieView:load()
 if tab:hasloadedurl(true) then
  --[[tab:runjs("console.log(document.cookie);console.log('done');",tab.url,0)]]
  --tab:runluaonlog('"done"','CookieView:display()')
  --tab:runjs("results={};results.cookie=document.cookie;window.chrome.webview.postMessage(results);window.chrome.webview.postMessage('done');")
  tab:runluaafterjs('CookieView:display()','results={};results.cookie=document.cookie;JSON.stringify(results)')
  
 end
end