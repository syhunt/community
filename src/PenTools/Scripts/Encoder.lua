Base64Encoder = {}

function Base64Encoder:view()
  local html = [[
  <table width="100%" height="100%"><tr><td width="50%">
  <plaintext.editor id="data"></plaintext>
  </td><td style="width:3px;"></td><td width="50%">
  <plaintext.editor id="result" readonly="true"></plaintext></td></tr></table>
  <button onclick="Base64Encoder:encode()">Encode</button>
  <button onclick="Base64Encoder:decode()">Decode</button>
  <button onclick="Base64Encoder:view()">Reset</button>
  ]]
  browser.loadpagex({name='b64encoder',html=html,table='Base64Encoder.ui'})
end

function Base64Encoder:encode()
 local ui = self.ui
 ui.result.value = ctk.base64.encode(ui.data.value)
end

function Base64Encoder:decode()
 local ui = self.ui
 ui.result.value = ctk.base64.decode(ui.data.value)
end

URLEncoder = {}

function URLEncoder:view()
  local html = [[
  <table width="100%" height="100%"><tr><td width="50%">
  <plaintext.editor id="data"></plaintext>
  </td><td style="width:3px;"></td><td width="50%">
  <plaintext.editor id="result" readonly="true"></plaintext></td></tr></table>
  <button onclick="URLEncoder:encode(false)">Encode</button>
  <button onclick="URLEncoder:encode(true)">Encode (Full)</button>
  <button onclick="URLEncoder:decode()">Decode</button>
  <button onclick="URLEncoder:view()">Reset</button>
  ]]
  browser.loadpagex({name='urlencoder',html=html,table='URLEncoder.ui'})
end

function URLEncoder:encode(full)
  local ui = self.ui
  if full == true then
   ui.result.value = ctk.url.encodefull(ui.data.value)
  else
   ui.result.value = ctk.url.encode(ui.data.value)
  end
end

function URLEncoder:decode()
  local ui = self.ui
  ui.result.value = ctk.url.decode(ui.data.value)
end

MD5Encoder = {}

function MD5Encoder:view()
  local html = [[
  <table width="100%" height="100%"><tr><td width="50%">
  <plaintext.editor id="data"></plaintext>
  </td><td style="width:3px;"></td><td width="50%">
  <plaintext.editor id="result" readonly="true"></plaintext></td></tr></table>
  <button onclick="MD5Encoder:encode()">Encode</button>
  <button onclick="MD5Encoder:view()">Reset</button>
  ]]
  browser.loadpagex({name='md5encoder',html=html,table='MD5Encoder.ui'})
end

function MD5Encoder:encode()
  local ui = self.ui
  ui.result.value = ctk.crypto.md5(ui.data.value)
end

SHA1Encoder = {}

function SHA1Encoder:view()
  local html = [[
  <table width="100%" height="100%"><tr><td width="50%">
  <plaintext.editor id="data"></plaintext>
  </td><td style="width:3px;"></td><td width="50%">
  <plaintext.editor id="result" readonly="true"></plaintext></td></tr></table>
  <button onclick="SHA1Encoder:encode()">Encode</button>
  <button onclick="SHA1Encoder:view()">Reset</button>
  ]]
  browser.loadpagex({name='sha1encoder',html=html,table='SHA1Encoder.ui'})
end

function SHA1Encoder:encode()
  local ui = self.ui
  ui.result.value = ctk.crypto.sha1(ui.data.value)
end
