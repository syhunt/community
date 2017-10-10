XHREditor = {}

function XHREditor:doreq()
 local ui = self.ui
 browser.options.showheaders = true
 local req = {}
 req.method = ui.method.value
 req.postdata = ui.postdata
 req.url = ui.url.value
 req.details = 'Browser Request (Via XHR Editor)'
 req.headers = ui.reqheaders.value
 req.username = ui.username.value
 req.password = ui.password.value
 req.callback = 'tab.capturebrowser = true'
 tab:sendxhr(req)
end

function XHREditor:sendrequest()
 local ui = self.ui
 if ui.url.value ~= '' then
  if ctk.url.crack(tab.url).host ~= ctk.url.crack(ui.url.value).host then
    tab.loadend = 'XHREditor:doreq()'
    tab.capturebrowser = false
    tab:gotourl(ui.url.value)
  else
   self:doreq()
  end
 else
  app.showmessage('No URL provided for request.')
 end
end

function XHREditor:vieweditor()
 if tab:hasloadedurl(true) then
  XHREditor:load(tab.url,'')
 end
end

function XHREditor:load(url,head)
 local html = PenTools:getfile('Scripts/XHREditor.html')
 if Fuzzer == nil then
  PenTools:dofile('Scripts/Fuzzer.lua')
 end
 browser.loadpagex({name='xhr editor',html=html,table='XHREditor.ui'})
 local ui = self.ui
 if url ~= nil then
  ui.url.value = url
 end
 if head ~= nil then
  ui.reqheaders.value = head
 end
end

function XHREditor:renderresponse()
 local ui = self.ui
 tab:gotourl(ui.url.value,ui.response.value)
end