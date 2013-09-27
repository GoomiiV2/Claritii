require "./libs/bit"

MISC = {};
local MOD_ADLER = 65521;

-- Alder-32
function MISC.Alder32(str)
	local a = 1;
	local b = 0;
	
	for i = 1, #str do
		local c = tonumber(str:sub(i,i));
		
		a = (a + c) % MOD_ADLER;
		b = (b + a) % MOD_ADLER;
	end
	
	return bit.bor(bit.blshift(b, 16), a);
end