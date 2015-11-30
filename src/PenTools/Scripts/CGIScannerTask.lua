 require "SelHTTP"
 
 print('Starting CGI Scanner...')
 task.caption = 'CGI Scanner'
 print('Path list file: '..params.pathlistfile)
 pathlist = slx.file.getcontents(params.pathlistfile)
 url = params.url
 method = params.method
 print('Target URL: '..url)
 print('Method: '..method)
 print('Path list: '..params.pathlistfile)
 
 http = sel_httprequest:new()
 http.description = 'CGI Scanner Request'
 p = slx.string.loop:new()
 p:load(pathlist)
 while p:parsing() do
  task:setprogress(p.curindex,p.count)
  http:open(method,slx.url.combine(url,p.current))
  if http.status == 200 then
   task:logrequest(http.requestinfo)
   printsuccess('Found: '..p.current)
  end
 end
 p:release()
 http:release()
 
 task.status = 'Done.'
 print(task.status)