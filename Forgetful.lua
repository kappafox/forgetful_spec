--[[
	Author: kappafox

--]]

-- Global/public variables to initialise saving
FG_Set1 = nil
FG_Set2 = nil
FG_Enabled = false
FG_DD1 = nil
FG_DD2 = nil
FG_Check = nil;

-- Local/private variables used during runtime
local spec1 = nil
local spec2 = nil
local message = nil;
local combat = false;


--[[====================================================
	Name: Forgetful_OnLoad(self, ...)
		Description: runs once when the xml frame is loaded by the game, used to register for further events
		Returns: Nothing
		Parameters:
			self	: 	a reference to the xml frame registered to this function
			...		:	any extra params that may be passed
	
		Notes:
====================================================--]]
function Forgetful_OnLoad(self)

	self:RegisterEvent("VARIABLES_LOADED");					-- for variable loading
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");		-- detecting spec switching
	self:RegisterEvent("PLAYER_REGEN_DISABLED");			-- both _ENABLED and _DISABLED are required as there is no enter/leave combat events
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
end


--[[====================================================
	Name: Forgetful_Queue()
		Description: A simple dummy function to test the capabilities of GetLFGQueueStats()
		Returns: Nothing
		Parameters: None
	
		Notes: Doesn't seem to work as of 5.2 due to changes to GetLFGQueueStats()
====================================================--]]
function Forgetful_Queue()
	local hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats()

	print("Leader Needs: " .. leaderNeeds)
	print("Tank Needs: " .. tankNeeds .. ", wait: " .. tankWait)
	print("Healer Needs: " .. healerNeeds .. ", wait: " .. healerWait)
	print("DPS Needs: " .. dpsNeeds  .. ", wait: " .. damageWait)
end


 --[[====================================================
	Name: Forgetful_OnEvent(self, event, ...)
		Description: Local event handler for spec changing
		Returns: Nothing
		Parameters:
			self	: 	a reference to the xml frame registered to this function
			event	:	a string detailing which registered event fired
			...		:	a table of any remaining params
	
		Notes:
====================================================--]]
function Forgetful_OnEvent(self, event, ...)

	--things done when the saved variables are loaded
	if(event == "VARIABLES_LOADED") then
		Forgetful_LoadInterface()	-- create the UI
	end
	
	--if you haven't turned the functionality on, don't respond to revents
	if(FG_Enabled == false) then
		return
	end
	
	--event fired when you change your talents, does not work for others
	if(event == "ACTIVE_TALENT_GROUP_CHANGED") then
		Forgetful_ChangeSpec(...);
	end
	
	--entering combat
	if(event == "PLAYER_REGEN_DISABLED") then
		combat = true;	--combat flag
	end
	
	--leaving combat
	if(event == "PLAYER_REGEN_ENABLED") then
		combat = false;
	end

end


 --[[====================================================
	Name: echo(message)
		Description: a simple print function that adds the addon name as a prefix
		Returns: Nothing
		Parameters:
			message	: 	any text you wish to print out
	
		Notes:
====================================================--]]
function echo(message)
	local blue = "[|cff3399FF".."Forgetful".."|r]:"
	print(blue .. message)
end

 --[[====================================================
	Name: Forgetful_ChangeSpec(spec)
		Description: Attempts to change your gear set when you change your spec.
		Returns: Nothing
		Parameters:
			spec	: 	a numerical indicator of the spec that was just changed into
			oldspec	:	a numerical indicator of the spec you changed out of
	
		Notes:
====================================================--]]
function Forgetful_ChangeSpec(spec, oldspec)

	--is there an equipment set paired with the spec you changed to
	if(spec == 1 and FG_Set1 == nil) then
		echo("No equipment set is paired with this spec")
		return
	end
	
	--as above but for your second spec
	if(spec == 2 and FG_Set2 == nil) then
		echo("No equipment set is paired with this spec")
		return
	end
	
	--retrieving spec details from the server
	local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked = GetSpecializationInfo(GetSpecialization(), false, false, 1)	
	
	
	--sometimes the event fires twice but with null params, this supresses bad behaviour
	if(name == nil) then return end
	
	--if you are now in spec 1
	if(spec == 1) then
		local result = UseEquipmentSet(FG_Set1)	--attempt to change armour sets

		--successful change
		if(result == true) then
			echo("Equipment set '" .. FG_Set1 .. "' equiped for '" .. name .. "' spec ")
		else
			--did it fail because of combat?
			if(combat == true) then
				echo("Equipment set change failed! (In Combat)")
				return
			else
				
				--does that equipment set still even exist?
				if(GetEquipmentSetInfoByName(FG_Set1) == nil) then
					echo("Equipment set change failed! (Could not find set '" .. FG_Set1 .. "')")
					return
				end
				
				--sometimes it just fails without a reason
				echo("Equipment change failed! (Unknown reason)")				
				return
			end
		end
		
		return;
	end

	--the same procedure as above but for the second set
	if(spec == 2) then		
		if(UseEquipmentSet(FG_Set2) == true) then
			echo("Equipment set '" .. FG_Set2 .. "' equiped for '" .. name .. "' spec ");
			return
		else
			if(combat == true) then
				echo("Equipment set change failed! (In Combat)");
				return;
			else
			
				if(GetEquipmentSetInfoByName(FG_Set2) == nil) then
					echo("Equipment set change failed! (Could not find set '" .. FG_Set2 .. "')");
					return;
				end
			
				echo("Equipment change failed! (Unknown reason)");			
				return;
			end
		end
	end

end



 --[[====================================================
	Name: Forgetful_Eligble( )
		Description: Tests to see if a character has multiple specs
		Returns:
			boolean	: true if GetNumSpecGroups > 1, false otherwise
		Parameters: None
	
		Notes:
====================================================--]]
function Forgetful_Eligble( )
	
	--you must have more than 1 spec to use a spec changing addon!
	if(GetNumSpecGroups() > 1) then
		return true;
	else
		return false;
	end
end


 --[[====================================================
	Name: Forgetful_SlashHandler(msg, editbox)
		Description: accepts registered slash commands in game and acts on them
		Returns: Nothing
		Parameters:
			msg		: 	any text following the registered slash command
			editbox	:	a table reference to the source editbox that was used
	
		Notes:
====================================================--]]
function Forgetful_SlashHandler(msg, editbox)

	--Version Outputting
	if(msg == "ver" or msg == "version") then
		echo("Running Forgetful Version: " .. FG_VERSION);
		return
	end
	
	--Enabling the addon for your character
	if(msg == "enable") then	
		if(Forgetful_Eligble() == true) then		
			FG_Enabled = true;
			return true;
		end
		
		echo("Forgetful cannot be enabled with less then 2 specs");
		--not eligble
		return false	
	end
	
	--attempting to use commands without turning it on
	if(FG_Enabled == false) then
		echo("Forgetful is not set for this character, '/fg enable' to enable")
		return
	end
	
	--no text means they wish to open the spec switching panel
		
	Forgetful_UpdateIcons()	--refresh the spec icons before the panel opens up
	UIDropDownMenu_Initialize(Forgetful_dd_1, Forgetful_Dropdown_Initialise)	--initialise the two drop down boxes
	UIDropDownMenu_Initialize(Forgetful_dd_2, Forgetful_Dropdown_Initialise)
	Forgetful_Main:Show()	-- show the main window

end

--registering slash commands is quite picky about program location, best left here
SLASH_FORGETFUL1 = "/forgetful"
SLASH_FORGETFUL2 = "/forget"
SLASH_FORGETFUL2 = "/fg"

SlashCmdList["FORGETFUL"] = Forgetful_SlashHandler


 --[[====================================================
	Name: Forgetful_UpdateIcons()
		Description: updates the spec icons in the frame before the panel is opened
		Returns: Nothing
		Parameters: None
	
		Notes:
====================================================--]]
function Forgetful_UpdateIcons()

	if(GetActiveSpecGroup() == 1) then
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 1))
		
		Forgetful_Main_Spec1_Icon:SetTexture(iconTexture, false)
		spec1 = name
		
		
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 2));
		Forgetful_Main_Spec2_Icon:SetTexture(iconTexture, false)
		spec2 = name
		
		return
	end
	
	if(GetActiveSpecGroup() == 2) then
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 2));
		
		Forgetful_Main_Spec2_Icon:SetTexture(iconTexture, false)
		spec2 = name
			
			
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 1));		
		Forgetful_Main_Spec1_Icon:SetTexture(iconTexture, false)
		spec1 = name
	end

end


 --[[====================================================
	Name: Forgetful_Dropdown_Initialise(self, level)
		Description: initialised the dropdown/comboboxes
		Returns: Nothing
		Parameters:
			self	: 	a reference to the dropdown box being initialised
			level	: 	the internal level of this dropdown box
	
		Notes:
====================================================--]]
function Forgetful_Dropdown_Initialise(self, level)

	--no equipment sets saved so nothing to initialise
	if(GetNumEquipmentSets() == 0) then
	
		local item = UIDropDownMenu_CreateInfo()		-- an 'item' of the box
		item.text = "You have no saved equipment sets!"
		item.value = "no set"
		item.func = nil
		
		UIDropDownMenu_AddButton(item)	--add the empty item
		
		UIDropDownMenu_SetSelectedID(Forgetful_dd_1, 0)	--set the dropdown box to show this
		return
	end
	
	local item = nil;
	
	--if the box being initialised is the first
	if(self:GetName() == "Forgetful_dd_1") then
	
		--for each equipment set add an item
		for index = 1, GetNumEquipmentSets() do
			local name, icon, useless = GetEquipmentSetInfo(index)
			
			item = UIDropDownMenu_CreateInfo()
			item.text = name
			item.value = name
			item.name = "box"
			item.func = Forgetful_Dropdown_OnClick
			
			UIDropDownMenu_AddButton(item)
			item = nil
		end
			
		--add a 'none' selection at the end
		item = UIDropDownMenu_CreateInfo()
		item.text = "None"
		item.value = "None"
		item.name = "none"
		item.func = Forgetful_Dropdown_OnClick
		
		UIDropDownMenu_AddButton(item)
		item = nil
		
		
		--setting values for changing
		if(FG_DD1 ~= nil) then
			UIDropDownMenu_SetSelectedID(Forgetful_dd_1, FG_DD1)
		else
			UIDropDownMenu_SetSelectedID(Forgetful_dd_1, 0)
		end
		
	else
		--the second dropdown
		for index = 1, GetNumEquipmentSets() do
			local name, icon, useless = GetEquipmentSetInfo(index)
			
			item = UIDropDownMenu_CreateInfo()
			item.text = name
			item.value = name
			item.name = "box"
			item.func = Forgetful_Dropdown_OnClick2
			
			UIDropDownMenu_AddButton(item)
			item = nil
		end


		item = UIDropDownMenu_CreateInfo()
		item.text = "None"
		item.value = "None"
		item.name = "none"
		item.func = Forgetful_Dropdown_OnClick
		
		UIDropDownMenu_AddButton(item)
		item = nil
		
		if(FG_DD2 ~= nil) then
			UIDropDownMenu_SetSelectedID(Forgetful_dd_2, FG_DD2)
		else
			UIDropDownMenu_SetSelectedID(Forgetful_dd_2, 0)
		end
	end
end

 --[[====================================================
	Name: Forgetful_Dropdown_OnClick(self)
		Description: the function called when any dropdown item is clicked in the first dropdown
		Returns: Nothing
		Parameters:
			self	: 	a reference to the item in the dropdown that was clicked
	
		Notes:
====================================================--]]
function Forgetful_Dropdown_OnClick(self)

	-- 'none' option was selected
	if(self:GetText() == "None") then
		FG_DD1 = nil
		FG_Set1 = nil
	end

	UIDropDownMenu_SetSelectedID(Forgetful_dd_1, self:GetID())
	FG_DD1 = self:GetID()
	FG_Set1 = self:GetText()
	echo("Equipment set '" .. FG_Set1 .. "' now assigned to " .. spec1)
end


 --[[====================================================
	Name: Forgetful_Dropdown_OnClick2(self)
		Description: the function called when any dropdown item is clicked in the second dropdown
		Returns: Nothing
		Parameters:
			self	: 	a reference to the item in the dropdown that was clicked
	
		Notes:
====================================================--]]
function Forgetful_Dropdown_OnClick2(self)

	if(self:GetText() == "None") then
		FG_DD2 = nil
		FG_Set2 = nil
	end
	
	UIDropDownMenu_SetSelectedID(Forgetful_dd_2, self:GetID())
	FG_DD2 = self:GetID()
	FG_Set2 = self:GetText()
	echo("Equipment set '" .. FG_Set2 .. "' now assigned to " .. spec2)
end



 --[[====================================================
	Name: Forgetful_LoadInterface()
		Description: creation of interface features and parts
		Returns: Nothing
		Parameters: None
	
		Notes:
====================================================--]]
function Forgetful_LoadInterface()

	--building up the first drop down
	if(not Forgetful_dd_1) then
		CreateFrame("Button", "Forgetful_dd_1", Forgetful_Main, "UIDropDownMenuTemplate")
	end
	
	Forgetful_dd_1:SetParent(Forgetful_Main)	--parenting it to the frame
	Forgetful_dd_1:Show()
	Forgetful_dd_1:SetPoint("TOPRIGHT", -10, -50)
	Forgetful_dd_1:SetID(1)
	
	UIDropDownMenu_Initialize(Forgetful_dd_1, Forgetful_Dropdown_Initialise)
	UIDropDownMenu_SetWidth(Forgetful_dd_1, 100);
	UIDropDownMenu_SetButtonWidth(Forgetful_dd_1, 124)
	UIDropDownMenu_JustifyText(Forgetful_dd_1, "LEFT")
	
	if(not Forgetful_dd_2) then
		CreateFrame("Button", "Forgetful_dd_2", Forgetful_Main, "UIDropDownMenuTemplate")
	end
	
	Forgetful_dd_2:SetParent(Forgetful_Main)	
	Forgetful_dd_2:Show()
	Forgetful_dd_2:SetPoint("TOPRIGHT", -10, -130)
	Forgetful_dd_2:SetID(2)
	
	UIDropDownMenu_Initialize(Forgetful_dd_2, Forgetful_Dropdown_Initialise)
	UIDropDownMenu_SetWidth(Forgetful_dd_2, 100);
	UIDropDownMenu_SetButtonWidth(Forgetful_dd_2, 124)
	UIDropDownMenu_JustifyText(Forgetful_dd_2, "LEFT")
	

end