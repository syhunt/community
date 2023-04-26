SyCommands = {}

function SyCommands:Add()
 console.addcmd('enscript','SyCommands:EnableScriptCommands()','Enables additional script commands')
 console.addcmd('myip','SyCommands:MyIP()','Displays the local IP address')
 console.addcmd('rb [code]','ScriptRunner:runscript("rb",cmd.params)','Runs Ruby Code')
 console.addcmd('rbcs','SyCommands:RubyConsole()','Ruby Console')
 console.addcmd('run [filename]','SyCommands:RunScript(cmd.params)','Executes a script file in the Scripts directory (eg: run demo.js). Supports JS/Lua/PHP/Pascal/Perl/Python/Ruby/VB')
 console.addcmd('whois','SyCommands:Whois(tab.url)','Outputs the registrant of the domain name')
end

function SyCommands:CustomConsole(handler,fontcolor,bgcolor,script)
 if console.gethandler() ~= handler then 
  console.sethandler(handler)
  console.clear()
  console.setcolor(bgcolor)
  console.setfontcolor(fontcolor)
  ScriptRunner:runscript(handler,script)
 end
end

function SyCommands:PHPConsole()
 self:CustomConsole('php','#FFFFFF','#666699','echo("PHP/".phpversion());')
end

function SyCommands:RubyConsole()
 local msgscript = [[puts "Ruby/"+RUBY_VERSION]]
 self:CustomConsole('rb','#FFFFFF','#7d0000',msgscript)
end

function SyCommands:MyIP()
 local code = [[
 $hosts = gethostbynamel('');
 echo $hosts[0];
 ]]
 ScriptRunner:runscript('php',code)
end

function SyCommands:Whois(url)
 if tab:hasloadedurl(true) then
  PenTools:dofile("Scripts/commands/whois.lua")
  local whois = getwhois(url)
  p = ctk.string.loop:new()
  p:load(whois)
  while p:parsing() do
   print(p.current)
  end
  p:release()
 else
  print("No URL loaded.")
 end
end

function SyCommands:RunScript(filename)
 local fullfile = app.dir..'Scripts\\'..filename
 local ext = string.lower(ctk.file.getext(filename))
 if ctk.file.exists(fullfile) then
  local script = ctk.file.getcontents(fullfile)
  if ext == '.js' then
   tab:runjs(script)
  elseif ext == '.lua' then
   assert(loadstring(script))()
  else
   ScriptRunner:runscriptfile(fullfile)
  end
 else
  if filename ~= '' then
   print('Script "'..filename..'" not found.')
  end
 end
end

function SyCommands:EnableScriptCommands()
 print('Additional script commands enabled.')
 console.addcmd('jsc [code]','ScriptRunner:runscript("jsc",cmd.params)','Runs JScript Code (Microsoft Engine)')
 console.addcmd('pas [code]','ScriptRunner:runscript("pas",cmd.params)','Runs Pascal Code')
 console.addcmd('php [code]','ScriptRunner:runscript("php",cmd.params)','Runs PHP Code')
 console.addcmd('phpcs','SyCommands:PHPConsole()','PHP Console')
 console.addcmd('pl [code]','ScriptRunner:runscript("pl",cmd.params)','Runs Perl Code')
 console.addcmd('py [code]','ScriptRunner:runscript("py",cmd.params)','Runs Python Code')
 console.addcmd('vb [code]','ScriptRunner:runscript("vb",cmd.params)','Runs VBScript Code')
end