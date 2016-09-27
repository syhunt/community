PageInfo = {}

function PageInfo:getobjects_count()
 local s = ctk.string.list:new()
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
 local html = ctk.string.list:new()
 local p = ctk.string.loop:new()
 p:load(tab.reslist)
 while p:parsing() do
    src = p.current
    urlext = string.lower(ctk.url.getfileext(src))
    filename = ctk.url.getfilename(src)
    if ctk.string.beginswith(filename,'?') == false then
     filename = ctk.string.before(filename,'?')
    end
    src = ctk.html.escape(src)
    if tag == 'option' then
     line = '<option filename="n'..ctk.html.escape(ctk.url.getfileext(filename))..'" value="'..src..'">'..ctk.url.getfilename(src)..'</option>'
     if html:indexof(line) == -1 then html:add(line) end
    else
     if ctk.re.match(urlext,'.bmp|.gif|.ico|.jpg|.jpeg|.png|.svg') == true then
      line = [[<img src="]]..src..[[" onclick="window.open(Sandcat.Base64Decode(']]..ctk.base64.encode(src)..[['))"/>]]
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
 local ct = ctk.http.getheader(r.rcvdheaders,'Content-Type')
 local urlext = string.lower(ctk.url.getfileext(r.url))
 if ct == '' then ct = urlext end
 tab:showcodeedit(r.responsetext,ct)
end

function PageInfo:openobject(url)
 local ui = self.ui
 if url == '' then
  url = ui.objlist.value
 end
 local urlext = string.lower(ctk.url.getfileext(url))
 if ReqViewer == nil then
  PenTools:dofile('Scripts/ReqViewer.lua')
 end
 ReqViewer:viewcached(url)
 --[[if ctk.re.match(urlext,'.bmp|.gif|.ico|.jpg|.jpeg|.png|.svg') == true then
  browser.bottombar:loadx('<style>html { background-color:#e2e2e5;}</style><img src="'..ctk.html.escape(url)..'">','PageInfo.ui')
 else 
  URLGet:get(url,PageInfo.requestdone)
 end ]]
end

function PageInfo:load()
 if tab:hasloadedurl(true) then
  local html = PenTools:getfile('Scripts/PageInfo_Objects.html')
  html = ctk.string.replace(html,'<!pageobjects>',self:getobjects('option'))
  browser.loadpagex('resexplorer',html,'PageInfo.ui')
 end
end

function PageInfo:viewimages()
 if tab:hasloadedurl(false) then
  local html = PenTools:getfile('Scripts/PageInfo_Images.html')
  html = ctk.string.replace(html,'<!url>',ctk.html.escape(tab.url))
  html = ctk.string.replace(html,'<!images>',self:getobjects('picture'))
  local j = {}
  j.title = 'Images'
  j.icon = 'url(PenTools.scx#images\\icon_image.png)'
  j.activepage = 'browser'
  if browser.newtabx(j) ~= 0 then
   tab:gotourl('about:images',html)
  end
 end
end