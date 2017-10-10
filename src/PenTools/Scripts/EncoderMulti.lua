MultiEncoder = {}
MultiEncoder.default_scriptdir = app.dir..'Scripts\\User\\'

function MultiEncoder:setresult(r)
 local ui = self.ui
 ui.result.value = r
end

function MultiEncoder:runscript(mode)
 local ui = self.ui
 ScriptRunner:reset()
 local encscript = ui.script.value
 encscript = encscript..' MultiEncoder:setresult('..mode..'(MultiEncoder.ui.data.value))'
 ui.btnrun.enabled = false
 tab.status = 'Executing...'
 assert(loadstring(encscript))()
 ui.btnrun.enabled = true
 tab.status = 'Done.'
end

function MultiEncoder:reset()
 local ui = self.ui
 ui.data.value = ''
end

function MultiEncoder:openlua()
 local ui = self.ui
 local f = ui.scriptlist.value
 local fcontents = ''
 if ctk.file.exists(self.default_scriptdir..f) then
  fcontents = ctk.file.getcontents(self.default_scriptdir..f)
 end
 ui.script.value = fcontents
end

function MultiEncoder:loadencoder(script)
 self:loadscript(PenTools.filename,'Scripts/encode/'..script..'.lua')
end

function MultiEncoder:loadscript(package,script)
 local ui = self.ui
 local code = browser.getpackfile(package,script)
 ui.script.value = code
end

function MultiEncoder:viewencoders()
 self:vieweditor('Encode')
end

function MultiEncoder:encoder_changed()
 local ui = self.ui
 self:loadencoder(ui.encoder.value)
end

function MultiEncoder:vieweditor(mode,script,pakfilename)
 local defaultencoder = PenTools:getfile('Scripts/encode/base64.lua')
 local html = PenTools:getfile('Scripts/EncoderMulti.html')
 if script ~= nil then
  defaultencoder = browser.getpackfile(pakfilename,script)
 end
 browser.loadpagex({name='encoder',html=html,table='MultiEncoder.ui'})
 local ui = self.ui
 ui.btnrun:setattrib('onclick',"MultiEncoder:runscript('"..mode.."')")
 ui.btncaption.value = mode
 ui.btnrunicon:setattrib('src','Resources.pak#16\\icon_run.png')
 ui.script.value = defaultencoder
end
