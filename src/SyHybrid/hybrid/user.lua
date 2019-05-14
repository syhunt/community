SyHybridUser = {}

function SyHybridUser:BuyNow()
    browser.newtab('http://www.syhunt.com/en/?n=Pricing.AppScanner')
end

function SyHybridUser:CheckInst()
    local stat = symini.checkinst()
	if stat.result == false then
	    app.showalert(stat.resultstr)
	    if stat.offline == false then
		  self:Register(true)
		end
	end
end

function SyHybridUser:GenerateWebAPIKey()
    local k = symini.genwebapikey()
    if k.result == true then
	  app.showalerttext(k.key) 
	else
	  app.showalert('Make sure the web API server is running.')
	end
end

function SyHybridUser:ContactSupport()
	local configfile=app.dir..'\\Config\\Smrtupd.xcfg'
	local username=xmlinifile_readstring(configfile,'config','login','')
	local r = ctk.string.list:new()
	local ver = ctk.file.getver(app.dir..'\\SyHybrid.exe')
	local redir = 'welcome'

	r:add('<form method="POST" action="http://www.syhunt.com/index_forms.php" name="f">')
	r:add('<fieldset><legend style="color:black">Contact Support</legend>')
	r:add('<input type=hidden name=pname value="sc">')
	r:add('<input type=hidden name=type value="supportscx">')
	r:add('<input type=hidden name=intel value="'..redir..'">')
	r:add('<input type=hidden name=country value="-">')
	r:add('<input type=hidden name=phone value="-">')
	r:add('<input type=hidden name=product value="Syhunt '..ver..'">')
	r:add('<input type=hidden name=ptkey value="'..symini.getptk()..'">')
	r:add('Syhunt Version: <b>'..ver..'</b><br><br>')
	if self:IsValidUser(username) then
		r:add('<input type=hidden name=name value=user:"'..username..'">')
		r:add('<input type=hidden name=company value="-">')
		r:add('<input type=hidden name=email value="not@needed">')
		r:add('Username: <b>'..username..'</b><br><br>')
	else
		r:add('Name: <input type="text" name="name">&nbsp;<b>*</b><br>')
		r:add('Company: <input type="text" name="company">&nbsp;<b>*</b><br>')
		r:add('Email: <input type="text" name="email">&nbsp;<b>*</b><br><br>')
	end
	r:add('Questions or Comments: <textarea name="comments" cols="50" rows="10" class="textbox"></textarea>&nbsp;<b>*</b><br><br>')
	if self:IsValidUser(username)==false then
		r:add('<b>*</b> Indicates required fields<br><br>')
	end
	r:add('</fieldset>')
	r:add('<button type="submit" role="default-button">Submit</button>')
	r:add('<button type="reset">Reset</button>')
	r:add('</form>')

	local j = {}
	j.title = 'Contact Support'
	j.icon = 'url(SyHybrid.scx#images\\16\\contact.png)'
	j.html = r.text
	browser.newtabx(j)
	r:release()
end

function SyHybridUser:IsOptionAvailable(warnuser)
  local v = (symini.info.modename ~= 'Community Edition')
  if warnuser == true and v == false then
    app.showalert('This option is not available in the Community Edition.')
  end
  return v
end

function SyHybridUser:IsMethodAvailable(method,warnuser)
  local warnuser = warnuser or false
  local mode = symini.info.modename
  local v=true
  if mode == 'Community Edition' then
    if method == 'fileinc' then v=false end
    if method == 'unvredir' then v=false end
    if method == 'phptop5' then v=false end
    if method == 'structbf' then v=false end
    if warnuser == true and v == false then
      app.showalert('This method is not available in the Community Edition.')
    end
  end
  return v
end

function SyHybridUser:IsValidUser(user)
	local v=true
	if user == '' then v=false end
	return v
end

function SyHybridUser:Register(warnlimit)
	local k = app.showinputdialog('Enter your Pen-Tester Key:','')
	if k ~= '' then
	    local res = symini.setptk(k)
		app.showmessagex(res.resulthtml)
		if res.result == false then
		  browser.exit()
		end
	else
		if warnlimit then
			app.showmessagesmpl('Syhunt needs a valid key to run.')
			browser.exit()
		end
	end
end
