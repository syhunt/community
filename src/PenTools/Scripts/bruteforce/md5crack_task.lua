 local us = require 'Underscript.Runner'
 us.options.useglobals = true
 task.caption = 'MD5 Brute Force'
 task.status = 'Checking...'
 print('MD5 Brute Force (By Braindisorder)')
 found = ''
 s_charset = paramstr('charset','abcdefghijklmnopqrstuvwxyz')
 s_maxcount = paramstr('maxcount','1')
 s_md5 = paramstr('md5','')
 us.run.php(task:getpackfile('PenTools.scx','Scripts/bruteforce/md5crack.php'))
 if found ~= '' then
  task.status = 'Found match: '..found
  printsuccess()
 else
  task.status = 'No matches found.'
  printfailure()
 end
