require "SyMini"
require "Catalunya"

task.caption = 'Syhunt Dynamic Login Task'
--task.tag = params.sessionname
--task:setscript('ondblclick',"browser.showbottombar('task messages')")

print('Login Type: '..params.type)

if params.type == 'SeleniumUI' then
    params.type = 'Selenium'
    params.headless = false
    print('Headless mode off.')
end

print('Please, wait...')
lres = symini.logincheck(params)
if lres.success == true then
  printsuccess('Successful login.')
  if lres.retries > 0 then
    print('after '..tostring(lres.retries)..' retry attempt(s).')
  else
    print('Nailed it on the first try.')
  end
  task:browserdostring('SyhuntDynamic:AugmentedLoginPreview("'..params.type..'","'..ctk.base64.encode(params.url)..'",[['..lres.screenshot..']])')
else
  printfailure(lres.errormsg)
  if lres.retries > 0 then
    print('Stopped after '..tostring(lres.retries)..' failed retry attempt(s).')
  end  
end