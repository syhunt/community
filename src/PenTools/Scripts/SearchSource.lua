SearchSource = {}
SearchSource.uitable = 'SearchSource.ui'
SearchSource.page = [[
  <style>body { overflow-x: hidden; }</style>
  <input id="searchtext" type=text style="width:300px;" value="" novalue="Find...">
  <button onclick="SearchSource:go()">Search</button>
  &nbsp;&nbsp;<button type="checkbox" id="matchcase" checked="checked">Match case</button>
  <br><br>
]]

function SearchSource:go()
 local ui = self.ui
 self:search(ui.searchtext.value)
end

function SearchSource:match(substring,string,matchcase)
 local r = false
 if matchcase == false then
  substring = string.lower(substring)
  string = string.lower(string)
 end
 if string.find(substring,string) ~= nil then
  r = true else r = false
 end
 return r
end

function SearchSource:search(text)
  if self.ui == nil then
   self:load()
  end
  local ui = self.ui
  local p = ctk.string.loop:new()
  local html = ctk.string.list:new()
  local source = tab.source
  local hl = ''
  local matchcase = ui.matchcase.value
  local found = false
  if matchcase == '' then matchcase = true end
  p:load(source)
  html:add('<table>')
 if text ~= '' then
  while p:parsing() do
   if self:match(p.current,text,matchcase) == true then
    hl = ctk.html.escape(p.current)
    if matchcase == true then
     hl = ctk.string.replace(hl,text,'<font style="background-color:yellow;">'..text..'</font>')
    end
    found = true
    html:add('<tr><td><a href="#" onclick="tab:gotosrcline('..p.curindex..')">'..p.curindex..'</a></td><td style="width:20px;"></td><td>'..hl..'</td></tr>')
   end
  end
 end
  html:add('</table>')
  if text ~= '' then
   if found == false then
   html:add('<b>Search string not found.</b>')
   end
  end
  --browser.bottombar:loadx(self.page..html.text,self.uitable)
  browser.loadpagex({name='search source',html=self.page..html.text,table=self.uitable})
  ui.searchtext.value = text
  ui.matchcase.value = matchcase
  html:release()
  p:release()
end

function SearchSource:load()
 browser.loadpagex({name='search source',html=self.page,table=self.uitable})
end