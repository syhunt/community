require 'SyMini'
require 'Repmaker'
task.caption = 'Syhunt Report Maker Task'

rm = SyRepmaker:new()
rm.Filename = params.filename
rm.SessionName = params.session_name
rm.SessionDir = params.session_dir
rm.Template = params.template_name
rm.VulnSortMethod = params.template_sort
if params.reptitle ~= '' then 
 rm.ReportTitle = params.reptitle
end

ro = ctk.string.loop:new()
ro:load(params.template_selection)
while ro:parsing() do
 rname = ctk.string.before(ro.current, '=')
 rvalue = ctk.string.after(ro.current, '=')
 if rvalue == '1' then
  rm:setincludeitem(rname,true) 
 else
  rm:setincludeitem(rname,false)  
 end
end
ro:release()

task.status = 'Generating report...'
print('Generating report for session: '..params.session_name)
print('Template: '..params.template_name)
print('Output filename: '..ctk.file.getname(params.filename))
--print('Template Selection: '..params.template_selection)
rm:savereport()
if ctk.file.exists(params.filename) then
  printsuccess('Report saved to: '..params.filename)
  task.status = 'Report saved.'
 if params.canopenreport == 'true' then
   print('Opening report...')
   if rm.CanOpenInBrowser == true then
     task:browsernewtab(params.filename)
   else
    ctk.file.exec(params.filename)
   end
   print('Done.')
 end
else
  task.status = 'Error generating report.'
  printfailure('Error generating report.')
end

rm:release()