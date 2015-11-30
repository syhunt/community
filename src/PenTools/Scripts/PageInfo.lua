PageInfo = {}

function PageInfo:getobjects_count()
 local s = slx.string.list:new()
 s.text = tab.reslist
 local c = s.count
 s:release()
 return c
end

function PageInfo:getobjects(tag)
 local list = ''
 local line = ''
 local src = ''
 local urlext = ''
 local comburl = ''
 local filename = ''
 local html = slx.string.list:new()
 local p = slx.string.loop:new()
 p:load(tab.reslist)
 while p:parsing() do
    src = p.current
    urlext = string.lower(slx.url.getfileext(src))
    filename = slx.url.getfilename(src)
    if slx.string.beginswith(filename,'?') == false then
     filename = slx.string.before(filename,'?')
    end
    src = slx.html.escape(src)
    if tag == 'option' then
     line = '<option filename="n'..slx.html.escape(slx.url.getfileext(filename))..'" value="'..src..'">'..slx.url.getfilename(src)..'</option>'
     if html:indexof(line) == -1 then html:add(line) end
    else
     if slx.re.match(urlext,'.bmp|.gif|.ico|.jpg|.jpeg|.png|.svg') == true then
      line = [[<img src="]]..src..[[" onclick="window.open(Sandcat.Base64Decode(']]..slx.base64.encode(src)..[['))"/>]]
      if html:indexof(line) == -1 then html:add(line) end
     end
    end
 end
 html:sort()
 list = html.text
 p:release()
 html:release()
 return list
end

function PageInfo:requestdone(r)
 local ct = slx.http.getheader(r.rcvdheaders,'Content-Type')
 local urlext = string.lower(slx.url.getfileext(r.url))
 if ct == '' then ct = urlext end
 tab:showcodeedit(r.responsetext,ct)
end

function PageInfo:openobject(url)
 local ui = self.ui
 if url == '' then
  url = ui.objlist.value
 end
 local urlext = string.lower(slx.url.getfileext(url))
 if ReqViewer == nil then
  PenTools:dofile('Scripts/ReqViewer.lua')
 end
 ReqViewer:viewcached(url)
 --[[if slx.re.match(urlext,'.bmp|.gif|.ico|.jpg|.jpeg|.png|.svg') == true then
  browser.bottombar:loadx('<style>html { background-color:#e2e2e5;}</style><img src="'..slx.html.escape(url)..'">','PageInfo.ui')
 else 
  URLGet:get(url,PageInfo.requestdone)
 end ]]
end

function PageInfo:load()
 if tab:hasloadedurl(true) then
  local html = PenTools:getfile('Scripts/PageInfo_Objects.html')
  html = slx.string.replace(html,'<!pageobjects>',self:getobjects('option'))
  browser.loadpagex('resexplorer',html,'PageInfo.ui')
 end
end

function PageInfo:viewimages()
 if tab:hasloadedurl(false) then
  local html = PenTools:getfile('Scripts/PageInfo_Images.html')
  html = slx.string.replace(html,'<!url>',slx.html.escape(tab.url))
  html = slx.string.replace(html,'<!images>',self:getobjects('picture'))
  local j = {}
  j.title = 'Images'
  j.icon = 'url(PenTools.scx#images\\icon_image.png)'
  j.activepage = 'browser'
  if browser.newtabx(j) ~= 0 then
   tab:gotourl('about:images',html)
  end
 end
end