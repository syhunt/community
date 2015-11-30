URLGet = {}

function URLGet:get(url,cb,canlog)
  self.url = url
  self.callback = cb
  self.responsetext = ''
  self.rcvdheaders = ''
  if canlog == nil then
   canlog = true
  end
  self:get_direct()
end

function URLGet:get_direct()
  local http = PenTools:NewHTTPRequest()
  http:open('GET',self.url)
  self.responsetext = http.text
  self.rcvdheaders = http:getheader()
  http:release()
  self:callback(self)
end