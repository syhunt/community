HeadView = {}

function HeadView:load()
 if tab:hasloadedurl(true) then
  if tab.sentheaders ~= '' then
   local html = PenTools:getfile('Scripts/HeadView.html')
   browser.bottombar:loadx(html,'HeadView.ui')
   local ui = self.ui
   ui.rcvdheader.value = tab.rcvdheaders
   ui.sentheader.value = tab.sentheaders
   ui.banner.value = ctk.html.escape(ctk.http.getheader(tab.rcvdheaders,'Server'))
  else
   PenTools:ViewCachedPage()
   browser.bottombar:eval([[
   $("div[panel='panel-headers']").current = true;
   SandcatHandlers.expand_tab("panel-headers");
   ]])
  end
 end
end