html = slx.string.list:new()
p = slx.html.parser:new()
p:load(tab.source)
while p:parsing() do
 if p.tagname == 'a' then
   href = slx.html.escape(p:getattrib('href'))
   if href ~= '' then
    html:add('<a href="'..href..'" target="new">'..href..'</a><br>')
   end
 end
end
browser.newtab(tab.url,html.text)
p:release()
html:release()