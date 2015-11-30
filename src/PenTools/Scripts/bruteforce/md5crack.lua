MD5CrackPHP = {}

function MD5CrackPHP:run()
 local ui = self.ui
 local script = PenTools:getfile('Scripts/bruteforce/md5crack_task.lua')
 local j = slx.json.object:new()
 j.charset = ui.charset.value
 j.maxcount = ui.maxcount.value
 j.md5 = ui.md5.value
 tab:runtask(script,tostring(j))
 j:release()
end

function MD5CrackPHP:load()
 local html = [[
  Charset: <input id=charset type=text style="width:30%%" value="abcdefghijklmnopqrstuvwxyz" novalue="Charset...">
  Max Length: <input id="maxcount" type="number" step="1" minvalue="1" value="8">
  MD5: <input id=md5 type=text style="width:30%%" value="900150983cd24fb0d6963f7d28e17f72" novalue="Your MD5...">
  <button onclick="MD5CrackPHP:run()">Run</button>
 ]]
 browser.loadpagex('md5crack',html,'MD5CrackPHP.ui')
end