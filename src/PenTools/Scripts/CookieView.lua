CookieView = {}

function CookieView:display()
  local cktable = ''
  local cookie = tab.lastjslogmsg
  cookie = slx.string.replace(cookie,'; ','\n')
  if cookie ~= '' then
   cktable = '<table border=1 width="100%"><tr style="color:gray;"><td>Cookie</td><td>Value</td></tr>'
   p = slx.string.loop:new()
   p:load(cookie)
   while p:parsing() do
    local ckname = slx.html.escape(slx.string.before(p.current,'='))
    local ckvalue = slx.html.escape(slx.string.after(p.current,'='))
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
  browser.bottombar:loadx(html)
end

function CookieView:load()
 if tab:hasloadedurl(true) then
  tab:runluaonlog('done','CookieView:display()')
  tab:runjs("console.log(document.cookie);console.log('done');",tab.url,0)
 end
end