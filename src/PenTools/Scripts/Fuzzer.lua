Fuzzer = {}
Fuzzer.default_jsdir = app.dir..'Scripts\\Fuzzer\\'
Fuzzer.default_jsfilters = [[
// Add your JS filters here. Examples:
// if (http.status == 404) { canlog = false; }
// if (http.responseText.search("doesn't exist") != -1) { canlog = false; }
]]

function Fuzzer:displaydiv(name,bool)
 local e = self.ui.element
 e:select('div[id="'..name..'"]')
 if bool == false then
  e:setstyle('display','none')
 else
  e:setstyle('display','block')
 end
end

function Fuzzer:mode_changed()
 local ui = self.ui
 local newmode = ui.mode.value
 ui.start.value = '0'
 ui.aend.value = '100'
 self:displaydiv('increment',false)
 self:displaydiv('startend',false)
 self:displaydiv('character',false)
 self:displaydiv('wordlist',false)
 if newmode == 'wordlist' then
  self:displaydiv('wordlist',true)
 end
 if newmode == 'number' then
  self:displaydiv('increment',true)
  self:displaydiv('startend',true)
 end
 if newmode == 'char_repeat' then
  self:displaydiv('increment',true)
  self:displaydiv('startend',true)
  self:displaydiv('character',true)
  ui.start.value = '1'
 end
 if newmode == 'ascii' then
  self:displaydiv('startend',true)
  ui.start.value = '32'
  ui.aend.value = '126'
 end
end

function Fuzzer:openjs()
 local ui = self.ui
 local f = ui.scriptlist.value
 local fcontents = ''
 if ctk.file.exists(self.default_jsdir..f) then
  fcontents = ctk.file.getcontents(self.default_jsdir..f)
 end
 ui.script.value = fcontents
end

function Fuzzer:get_scriptlist(ext)
 local p = ctk.string.loop:new()
 local flist = ctk.string.list:new()
 local l = ctk.dir.getfilelist(self.default_jsdir..'*'..ext)
 p:load(l)
 while p:parsing() do
  flist:add('<option>'..p.current..'</option>')
 end
 local result = flist.text
 flist:release()
 p:release()
 return result
end

function Fuzzer:loadui(url,script,ext)
  local html = PenTools:getfile('Scripts/Fuzzer.html')
  local advoptions = ''
  html = ctk.string.replace(html,'<!scriptlist>',self:get_scriptlist(ext))
  if ext == '.lua' then
   html = html..'<style>html { background-color:#e6fffa;}</style>'
   advoptions = PenTools:getfile('Scripts/ReqEditorLow_Adv.html')
  else
   html = html..'<style>html { background-color:#faf4c6;}</style>'
   advoptions = PenTools:getfile('Scripts/XHREditor_Adv.html')
  end
  html = ctk.string.replace(html,'<!advoptions>',advoptions)
  browser.loadpagex({name='fuzzer',html=html,table='Fuzzer.ui'})
  local ui = self.ui
  ui.isxhr.value = true
  ui.url.value = url..'{$1}'
  ui.labprogdir.value = app.dir
  ui.lablangext.value = ext
  ui.script.value = script
end

function Fuzzer:loadfromreqeditor(baseurl)
 local baseurl = self.ui.url.value
 self:loadui(baseurl,self.default_jsfilters,'.js')
end

function Fuzzer:view()
  self:loadui(tab.url,self.default_jsfilters,'.js')
end

function Fuzzer:view_lowlevel()
 local default_filters = [[
-- Add your Lua filters here. Examples:
-- if http.status == 404 then canlog = false end
-- if ctk.re.match(http.text,'someregex') == false then canlog = false end
-- if ctk.string.match(string.lower(http.text),'*error*') == false then canlog = false end
]]
  self:loadui(tab.url,default_filters,'.lua')
  local ui = self.ui
  local hdr = tab.sentheaders
  self:loadhost()
  if hdr == '' then
   hdr = 'GET /'..ctk.url.crack(tab.url).path..' HTTP/1.1\nHost: '..ui.host.value..'\nConnection: Keep-Alive'
  end 
  ui.divstandard:setstyle('display','none')
  ui.divlow:setstyle('display','block')
  ui.request.value = ctk.string.replace(hdr,' HTTP/','{$1} HTTP/')
  ui.islow.value = true
  ui.isxhr.value = false
end

function Fuzzer:loadhost()
 local ui = self.ui
 local url = ctk.url.crack(tab.url)
 local request = ui.request.value
 if ctk.http.getheader(request,'Host') ~= '' then
  url.host = ctk.http.getheader(request,'Host')
  url.host = ctk.string.trim(url.host)
  url.port = 80
  if ctk.string.match(url.host,'*:*') then
   url.port = ctk.string.after(url.host,':')
   url.host = ctk.string.before(url.host,':')
  end
 end
 ui.host.value = url.host
 ui.port.value = url.port
end

function Fuzzer:start()
 local ui = self.ui
 local script = PenTools:getfile('Scripts/FuzzerTask.lua')
 local j = ctk.json.object:new()
 j.filter = ui.script.value
 j.delay = ui.delay.value
 -- fuzzer mode
 j.mode = ui.mode.value
 j.wordlistfile = ui.wordlist.value
 j.char = ui.char.value
 j.i_start = ui.start.value
 j.i_end = ui.aend.value
 j.i_inc = ui.inc.value
 j.isxhr = ui.isxhr.value
 j.islow = ui.islow.value
 -- fuzzer mode end
 -- advanced options
 if ui.isxhr.value == true then
  j.method = ui.method.value
  j.baseurl = ui.url.value
  j.basepostdata = ui.postdata.value
  j.basereqheaders = ui.reqheaders.value
  j.username = ui.username.value
  j.password = ui.password.value
 end
 if ui.islow.value == true then
  j.host = ui.host.value
  j.port = ui.port.value
  j.baserequest = ui.request.value
  j.autocontentlen = ui.autocontentlen.value
  j.enablegzip = ui.enablegzip.value
  j.maxretry = ui.maxretry.value
 end
 -- advanced options end
 browser.options.showheaders = true
 tab.capturerealtime = false
 tab:runtask(script,tostring(j))
 j:release()
end
