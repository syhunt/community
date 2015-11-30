require "SelHTTP"
msg_nowordlist = 'No wordlist provided.'
do_req = do_xhr

function do_xhr(value)
 local j = slx.json.object:new()
 j.details = 'XHR Call (Via Fuzzer)'
 j.method = method
 j.url = slx.string.replace(baseurl,'{$1}',value)
 j.postdata = slx.string.replace(basepostdata,'{$1}',value)
 j.headers = slx.string.replace(basereqheaders,'{$1}',value)
 j.filter = filter
 j.username = username
 j.password = password
 task:sendxhr(tostring(j))
 j:release()
 slx.utils.delay(delay)
end

function do_lowlevel(value)
 canlog = true
 local request = slx.string.replace(baserequest,'{$1}',value)
 http:openlow(host,port,request)
  if http.error == 0 then
   assert(loadstring(filter))()
   if canlog == true then
    task:logrequest(http.requestinfo)
   end
  end
 slx.utils.delay(delay)
end

function setprogress(pos,max)
  --task.status = 'Sending requests ('..pos..' of '..max..')...'
  task:setprogress(pos,max)
end

function run_wordlist()
 print('Running [Wordlist]...')
 if wordlistfile == '' then
  print(msg_nowordlist)
  task:showmessage(msg_nowordlist)
 else
  if slx.file.exists(wordlistfile) then
   local list = slx.file.getcontents(wordlistfile)
   p = slx.string.loop:new()
   p:load(list)
   while p:parsing() do
    setprogress(p.curindex,p.count)
    do_req(p.current)
   end
   p:release()
  end
 end
end

function run_number()
 print('Running [Number]...')
 local i=i_start
 while i <= i_end do
  setprogress(i,i_end)
  do_req(i)
  i = i+i_inc
 end
end

function run_ascii()
 print('Running [ASCII]...')
 for i=i_start,i_end do
  setprogress(i,i_end)
  do_req(string.char(i))
 end
end

function run_charrepeat()
 print('Running [Char Repeat]...')
 local i=i_start
 while i <= i_end do
  setprogress(i,i_end)
  do_req(string.rep(char,i))
  i = i+i_inc
 end
end

function run()
 if mode == 'wordlist' then run_wordlist() end
 if mode == 'number' then run_number() end
 if mode == 'ascii' then run_ascii() end
 if mode == 'char_repeat' then run_charrepeat() end
end

function start_xhr()
 print('XHR mode enabled.')
 method = paramstr('method','GET')
 baseurl = paramstr('baseurl','')
 basepostdata = paramstr('basepostdata','')
 basereqheaders = paramstr('basereqheaders','')
 username = paramstr('username','')
 password = paramstr('password','')
 tab = paramstr('tab','')
 run()
 print('Sending...')
end

function start_low()
 print('Low-level HTTP mode enabled.')
 do_req = do_lowlevel
 host = paramstr('host')
 port = paramint('port',80)
 baserequest = paramstr('baserequest')
 if slx.string.endswith(baserequest,'\n\n') == false then
  baserequest = baserequest..'\n\n'
 end
 http = sel_httprequest:new()
 http.description = 'HTTP Request (Via Fuzzer)'
 http.autolength = parambool('autocontentlen',true)
 http.enablegzip = parambool('enablegzip',true)
 http.maxretry = paramint('maxretry',0)
 run()
 http:release()
end

function start()
 task.caption = 'Fuzzer'
 task.status = 'Sending requests...'
 print('Starting Fuzzer...')
 starttime = os.time()
 do_req = do_xhr
 isxhr = parambool('isxhr',false)
 islow = parambool('islow',false)
 mode = paramstr('mode')
 filter = paramstr('filter')
 wordlistfile = paramstr('wordlistfile')
 char = paramstr('char')
 i_start = paramint('i_start',0)
 i_end = paramint('i_end',0)
 i_inc = paramint('i_inc',0)
 delay = paramint('delay',0)
 if isxhr == true then start_xhr() end
 if islow == true then start_low() end
 endtime = os.time()
 task.status = 'Done. '..os.difftime(endtime,starttime)..' second(s)'
 print('Done.')
end

start()