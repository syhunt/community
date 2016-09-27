-- Base64 Encoder
function Encode(s)
 return ctk.base64.encode(s)
end

function Decode(s)
 return ctk.base64.decode(s)
end