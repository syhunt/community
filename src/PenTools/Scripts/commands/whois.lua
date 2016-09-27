function getwhois(url)
 local us = require 'Underscript.Runner'
 local domain = ctk.url.crack(url).host
 local phpscript = PenTools:getfile('Scripts/commands/whois.php')
 ScriptRunner:reset()
 local result = ''
 us.run.php(phpscript)
 return result
end