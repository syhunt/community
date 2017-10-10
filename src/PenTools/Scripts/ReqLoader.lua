ReqLoader = {}

function ReqLoader:sendrequest(load)
 local ui = self.ui
 if ui.url.value ~= '' then
  browser.options.showheaders = true
  r = {}
  r.details = 'Browser Request (Via Editor)'
  r.method = ui.method.value
  r.url = ui.url.value
  r.headers = ui.reqheaders.value
  r.postdata = ui.postdata.value
  r.ignorecache = ui.ignorecache.value
  r.usecookies = ui.usecookies.value
  r.useauth = ui.useauth.value
  browser.options.showheaders = true
  if load == true then
   browser.setactivepage('browser')
   tab:loadrequest(r)
   else
   tab:sendrequest(r)
  end
 else
  app.showmessage('No URL provided for request.')
 end
end

function ReqLoader:viewloader()
 if tab:hasloadedurl(true) then
  ReqLoader:loadui(tab.url)
 end
end

function ReqLoader:loadui(url)
 local html = PenTools:getfile('Scripts/ReqLoader.html')
 browser.loadpagex({name='request loader',html=html,table='ReqLoader.ui'})
 local ui = self.ui
 if url ~= nil then
  ui.url.value = url
 end
end