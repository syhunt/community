-- Base64 Encoder
function Encode(s)
 return slx.base64.encode(s)
end

function Decode(s)
 return slx.base64.decode(s)
end