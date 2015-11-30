CodeEditor = {}
CodeEditor.title = 'Sandcat Editor'

function CodeEditor:drop()
 local ui = self.ui
 local slp = slx.string.loop:new()
 slp:load(tab.codeedit.droplist)
  if slp.count == 1 then
   ui.scriptfile.value = tab.codeedit.droplist
  else
   while slp:parsing() do
    self:openinnewtab(slp.current)
   end
  end
 slp:release()
end

function CodeEditor:new()
 local ui = self.ui
 tab.title = self.title
 tab.source = ''
 ui.scriptfile.value = ''
end

function CodeEditor:openinnewtab(f)
 local ui = self.ui
 self:newtab()
 ui.scriptfile.value = f
 slx.utils.delay(100)
end

function CodeEditor:open(f)
 local ui = self.ui
 if f == undefined then
  f = ui.scriptfile.value
 end
 if slx.file.exists(f) then
  --tab.codeedit:sethighlighter(slx.file.getext(f))
  --app.showmessage(tab.codeedit.text)
  tab.title = slx.file.getname(f)
	tab.downloadfiles = false
	tab.updatesource = false
	tab:gotourl(f)
	tab:runsrccmd('readonly',false)
	tab:runsrccmd('loadfromfile',f)
 end
 if f == '' then
  tab.title = self.title
  tab.source = ''
 end
end

function CodeEditor:save()
 local ui = self.ui
 local f = ui.scriptfile.value
 local ext = slx.file.getext(f)
 if slx.file.exists(f) then
  tab:runsrccmd('savetofile',f)
  ui.scriptfile.value = f
 else
  local sl = slx.string.list:new()
  sl.text = tab.source
  f = app.savefile('All files (*.*)|*.*',ext,'Untitled.'..ext)
  if f ~= '' then
   sl:savetofile(f)
   ui.scriptfile.value = f
  end
  sl:release()
 end
end

function CodeEditor:newtab()
 local j = {}
 j.icon = 'url(PenTools.scx#images\\icon_codeedit.png)'
 j.title = self.title
 j.toolbar = 'PenTools.scx#Scripts\\CodeEditor.html'
 j.table = 'CodeEditor.ui'
 j.activepage = 'source'
 j.showpagestrip = false
 if browser.newtabx(j) ~= '' then
  local filter = PenTools:getfile('Scripts/CodeEditor.flt')
  local html = PenTools:getfile('Scripts/CodeEditor.html')
  browser.setactivepage('source')
  --tab.codeedit.acceptdrop = true
  --tab.codeedit.dropend = 'CodeEditor:drop()'
  self.ui.scriptfile:setattrib('filter',slx.string.replace(filter,string.char(13)..string.char(10),''))
 end
end