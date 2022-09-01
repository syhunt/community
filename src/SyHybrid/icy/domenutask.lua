require "SyMini"
require "Catalunya"

task.caption = 'Syhunt Breach Domain Enumeration Task'
print('Enumerating domains...')
local enu = symini.enumeratesubdomains(params.domain)

local i = symini.breach:new()
i:start()

local dmlist = ctk.string.loop:new()
dmlist.text = enu.s
print('Total of domains found: '..tostring(enu.i))

while dmlist:parsing() do
    task:setprogress(dmlist.curindex,dmlist.count)
    local stat = i:checkdomainstatus(params.domain, dmlist.current)
    local j = ctk.json.object:new()
    j.caption = dmlist.current
    j.subitemcount = 3
    j.subitem1 = stat.ip
    j.subitem2 = stat.status
    j.subitem3 = dmlist.current
    runtabcmd('resaddcustomitem',tostring(j))
    j:release()
end

dmlist:release()
i:release()

task.status = 'Done.'
printsuccess(task.status)