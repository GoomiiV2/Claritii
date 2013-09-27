UII = {};

-- Creates a list box from an array
function UII.ListboxFromArray(LB_ID, LB_label, options, default)
	InterfaceOptions.AddChoiceMenu({id=LB_ID, label=LB_label, default});
	for i, v in pairs(options) do
		InterfaceOptions.AddChoiceEntry({menuId=LB_ID, label=i, val=v});
	end
end

-- Look up the strings using Lokii
function UII.ListboxFromArrayLokii(LB_ID, LB_label, options, default)
	InterfaceOptions.AddChoiceMenu({id=LB_ID, label=Lokii.GetString(LB_label),default=default});
	for i, v in pairs(options) do
		log(i);
		if (type(i) == "string") then
			InterfaceOptions.AddChoiceEntry({menuId=LB_ID, label=Lokii.GetString(i), val=v});
		else
			InterfaceOptions.AddChoiceEntry({menuId=LB_ID, label=Lokii.GetString(v), val=v});
		end
	end
end

-- ====================================
-- UI Callbacks                      --
-- ====================================

-- Call the given function when the UI option is changed
UII.UI_Callbacks = {};
UII.UI_Settings = {};

-- Register the function
function UII.AddUICallback(ID, func)
	UII.UI_Callbacks[ID] = func;
end

-- Check if the function should be called
function UII.CheckCallbacks(id, val)
	local func = UII.UI_Callbacks[id];
	if (func) then
		func(val);
	end
end

-- Set the settings table
function UII.RegisterSettingsTable(tbl)
	UII.UI_Settings = tbl;
end

-- A simple handler if all we want to do is set a value
function UII.AddUIVal(ID, var, func)
	UII.UI_Callbacks[ID] = 
		function(val)
			-- Check for a nested table
			local a,b = var:match"([^.]*).(.*)"
			
			if (a) then
				UII.UI_Settings[a][b] = val;
			else
				UII.UI_Settings[var] = val;
			end
			
			if (func) then
				func(val);
			end
		end
end