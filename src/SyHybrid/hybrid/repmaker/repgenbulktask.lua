require 'SyMini'
task.caption = 'Syhunt Report Maker Bulk Task'

function generatereport(session)
 rm = symini.repmaker:new()
 rm.Filename = params.outputdir..'\\Report_'..session..'_'..params.template..'.'..params.outputext
 rm.SessionName = session
 rm.SessionDir = symini.info.sessionsdir..'\\'..session..'\\'
 rm.Template = params.template
 --rm.VulnSortMethod = params.template_sort 

 task.status = 'Generating report...'
 print('Generating report for session: '..session)
 print('Output filename: '..ctk.file.getname( rm.Filename))
 rm:savereport(rm.Filename)
 if ctk.file.exists( rm.Filename) then
   printsuccess('Report saved to: '.. rm.Filename)
   task.status = 'Report saved.'
 else
   task.status = 'Error generating report.'
   printfailure('Error generating report.')
 end
 rm:release()
end

task.status = 'Generating reports...'
p = ctk.string.loop:new()
p:load(params.sessionlist)
while p:parsing() do
  generatereport(p.current)
end
p:release()