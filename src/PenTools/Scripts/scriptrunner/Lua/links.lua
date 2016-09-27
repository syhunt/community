html = ctk.string.list:new()
p = ctk.html.parser:new()
p:load(tab.source)
while p:parsing() do
 if p.tagname == 'a' then
   href = ctk.html.escape(p:getattrib('href'))
   if href ~= '' then
    html:add('<a href="'..href..'" target="new">'..href..'</a><br>')
   end
 end
end
browser.newtab(tab.url,html.text)
p:release()
html:release()