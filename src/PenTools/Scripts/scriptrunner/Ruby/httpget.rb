# See the log tab
require 'net/http'
resp = Net::HTTP.get 'www.syhunt.com', '/'
Sandcat.Write(resp)