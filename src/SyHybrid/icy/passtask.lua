require "SyMini"
require "Catalunya"

local pcount = 0
local totalpw = 0
local hashlist = ctk.string.list:new()
local pwlist = ctk.string.loop:new()

function updatelistview()
  while pwlist:parsing() do
    runtabcmd('resaddcustomitem',pwlist.current)
  end
  pwlist:clear()
  ctk.utils.delay(2000)
end

function newpassword(p)
  if hashlist:indexof(p.hash) == -1 then
    hashlist:add(p.hash)
    local j = ctk.json.object:new()
    j.caption = p.username
    j.subitemcount = 3
    j.subitem1 = p.password
    j.subitem2 = p.leakedfrom
    j.subitem3 = p.hash
    pwlist:add(tostring(j))
    j:release()
    --runtabcmd('resaddcustomitem',jsonstr)
    pcount = pcount+1
    totalpw = totalpw+1
    if pcount > 10000 then  
     pcount = 0
     updatelistview()
     task:browserdostring('app.update()')
    end
  end
end

task.caption = 'Syhunt Breach Password View Task'
print('Processing passwords from dump...')

local i = symini.breach:new()

i.onpasswordfound = newpassword
i:scanpwfile(params.filename)

updatelistview() -- final update

i:release()
pwlist:release()
hashlist:release()
task.status = tostring(totalpw)..' password(s)'
print(task.status)
runtabcmd('setstatus',task.status) 
task.status = 'Done.'
printsuccess(task.status)

