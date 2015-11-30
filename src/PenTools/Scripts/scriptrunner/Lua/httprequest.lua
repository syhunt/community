browser.options.showheaders = true

-- GET example
tab:sendrequest{
 method = 'GET',
 url = 'http://www.somehost.com/',
 ignorecache = true,
 useauth = true,
 usecookies = true,
 details = 'Request Example (GET)'
}

-- POST example
tab:sendrequest{
 method = 'POST',
 url = 'http://www.somehost.com/',
 postdata = 'id=1',
 details = 'Request Example (POST)'
}