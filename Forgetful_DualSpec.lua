--[[
	Author: Kappafox
		Date: 2/1/11
		Modified: 12/9/13
		Purpose: For the forgetful
--]]

--
Forgetful_DualSpec, FGDS = ...;		--removing pollution from the global name space



-- Global/public variables used for saving
FG_Set1 = nil						-- set for your first spec
FG_Set2 = nil						-- set for your second spec
FG_Enabled = false					-- master enable/disable
FG_DD1 = nil						-- dropdown 1
FG_DD2 = nil						-- dropdown 2
FG_DS_SETHELMS = false				-- change helms on spec change
FG_DS_HH1 = true;					-- change helm for spec1
FG_DS_HH2 = true;					-- change helm for spec2

-- Local/private variables used during runtime
local spec1 = nil					-- your first spec id
local spec2 = nil					-- your second spec id
local combat = false;				-- combat flag
local censor = false;				-- temporary flag to hide spam in the chatlog
local loaded = false;

-- constants
<<<<<<< HEAD
local FG_VERSION = "v1.0.5";		-- internal version, must be manually updated to match repo version
=======
local FG_VERSION = "v1.0.4b";		-- internal version, must be manually updated to match repo version
>>>>>>> 7273eb47444c93963b8e7ed1b3714a92c38adada





-- Small set of local functions that are used to filter out unwanted spam
-- during automated operation
--======================================================
function FGDS.filter(self, event, ...)
	if(censor == false) then
		return false, ...;
	else
		return true;
	end
end


function FGDS.Uncensor( )
	censor = false;
end


function FGDS.Censor( )
	censor = true;
	
	FGDS.Wait(6.0, FGDS.Uncensor, nil)
end
--======================================================



--[[====================================================
	Name: FGDS.OnLoad(self, ...)
		Description: runs once when the xml frame is loaded by the game, used to register for further events
		Returns: Nothing
		Parameters:
			self	: 	a reference to the xml frame registered to this function
			...		:	any extra params that may be passed
	
		Notes:
====================================================--]]
function FGDS.OnLoad(self)

	self:RegisterEvent("VARIABLES_LOADED");					-- for variable loading
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");		-- detecting spec switching
	self:RegisterEvent("PLAYER_REGEN_DISABLED");			-- both _ENABLED and _DISABLED are required as there is no enter/leave combat events
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	
end


--[[====================================================
	Name: FGDS.Queue()
		Description: A simple dummy function to test the capabilities of GetLFGQueueStats()
		Returns: Nothing
		Parameters: None
	
		Notes: Doesn't seem to work as of 5.2 due to changes to GetLFGQueueStats()
====================================================--]]
function FGDS.Queue()
	local hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats()

	print("Leader Needs: " .. leaderNeeds)
	print("Tank Needs: " .. tankNeeds .. ", wait: " .. tankWait)
	print("Healer Needs: " .. healerNeeds .. ", wait: " .. healerWait)
	print("DPS Needs: " .. dpsNeeds  .. ", wait: " .. damageWait)
end

 --[[====================================================
	Name: FGDS.OnEvent(self, event, ...)
		Description: Local event handler for spec changing
		Returns: Nothing
		Parameters:
			self	: 	a reference to the xml frame registered to this function
			event	:	a string detailing which registered event fired
			...		:	a table of any remaining params
	
		Notes:
====================================================--]]
function FGDS.OnEvent(self, event, ...)
	
	--things done when the saved variables are loaded
	if(event == "VARIABLES_LOADED") then
		FGDS.LoadInterface()	-- create the UI
		hooksecurefunc("SetActiveSpecGroup", FGDS.Censor)	--hook onto the activation of changing spec
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", FGDS.filter)	--add the filter object
		FGDS.SetCheckButtons();
		loaded = true;
		return;
	end
	
	--if you haven't turned the functionality on, don't respond to revents
	if(FG_Enabled == false) then
		return
	end
	
	--event fired when you change your talents, does not work for others
	--this will now be ignored until the variables are loaded
	if(event == "ACTIVE_TALENT_GROUP_CHANGED" and loaded == true) then
		FGDS.Wait(0.5, FGDS.ChangeSpec, ...);
		return;
	end
	
	--entering combat
	if(event == "PLAYER_REGEN_DISABLED") then
		combat = true;	--combat flag
		return;
	end
	
	--leaving combat
	if(event == "PLAYER_REGEN_ENABLED") then
		combat = false;
		return;
	end

end

function FGDS.SetCheckButtons( )
	--Helm visibility checkbox
	_G["FG_DS_Cbox_UseHelms"]:SetChecked(FG_DS_SETHELMS);
	
	--The two show helm checkboxes
	_G["FG_DS_Cbox_Helm1"]:SetChecked(FG_DS_HH1);
	_G["FG_DS_Cbox_Helm2"]:SetChecked(FG_DS_HH2);
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
	Name: FGDS.ChangeSpec(spec)
		Description: Attempts to change your gear set when you change your spec.
		Returns: Nothing
		Parameters:
			spec	: 	a numerical indicator of the spec that was just changed into
			oldspec	:	a numerical indicator of the spec you changed out of
	
		Notes:
====================================================--]]
function FGDS.ChangeSpec(spec, oldspec)

	--print(spec .. ":" .. oldspec);
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
	
	--trying to catch a rare event that seems to be happening
	--the spec comes back as 0 when changing during loading, assuming it's just nil being processed
	if((spec == oldspec) or spec == 0 or oldspec == 0 or spec == nil or oldspec == nil) then	--can't change into the same spec obviously
		return;
	end
	
	--retrieving spec details from the server
	local id, name, description, iconTexture, pointsSpent, background, previewPointsSpent, isUnlocked = GetSpecializationInfo(GetSpecialization(), false, false, 1)	
	
	
	--sometimes the event fires twice but with null params, this supresses bad behaviour on the server's behalf
	if(name == nil) then return end
	
	
	local changeInto;
	
	--set the set we will change into
	if(spec == 1) then
		changeInto = FG_Set1;
	else
		changeInto = FG_Set2;
	end
	
	--grab all the data we will need to perform the set change;
	local icon, setID, isEquipped, numItems, equippedItems, availableItems, missingItems, ignoredSlots = GetEquipmentSetInfoByName(changeInto)
	local result = UseEquipmentSet(changeInto)	--attempt to change armour sets
		


	--successful change
	if(result == true) then
		
		FGDS.SetHelm(spec);
		--are any of the components missing?
		if(missingItems > 0) then
			echo("Equipment set '" .. changeInto .. "' is missing items and may not have equipped properly!")
		else
			echo("Equipment set '" .. changeInto .. "' equipped for '" .. name .. "' spec ")
		end
	else
		--did it fail because of combat?
		if(combat == true) then
			echo("Equipment set change failed! (In Combat)")
			return
		else
			
			--does that equipment set still even exist?
			if(GetEquipmentSetInfoByName(changeInto) == nil) then
				echo("Equipment set change failed! (Could not find set '" .. changeInto .. "')")
				return
			end
			
			--sometimes it just fails without a reason
			echo("Equipment change failed! (Unknown reason)")				
			return
		end
	end
		
end



 --[[====================================================
	Name: FGDS.Eligble( )
		Description: Tests to see if a character has multiple specs
		Returns:
			boolean	: true if GetNumSpecGroups > 1, false otherwise
		Parameters: None
	
		Notes:
====================================================--]]
function FGDS.Eligble( )
	
	--you must have more than 1 spec to use a spec changing addon!
	if(GetNumSpecGroups() > 1) then
		return true;
	else
		return false;
	end
end


 --[[====================================================
	Name: FGDS.SlashHandler(msg, editbox)
		Description: accepts registered slash commands in game and acts on them
		Returns: Nothing
		Parameters:
			msg		: 	any text following the registered slash command
			editbox	:	a table reference to the source editbox that was used
	
		Notes:
====================================================--]]
function FGDS.SlashHandler(msg, editbox)

	--Version Outputting
	if(msg == "ver" or msg == "version") then
		echo("Running Forgetful DualSpec Version: " .. FG_VERSION);
		return
	end
	
	--Enabling the addon for your character
	if(msg == "enable") then	
		if(FGDS.Eligble() == true) then		
			FG_Enabled = true;
			FGDS.UpdateIcons()	--refresh the spec icons before the panel opens up
			UIDropDownMenu_Initialize(Forgetful_dd_1, Forgetful_Dropdown_Initialise)	--initialise the two drop down boxes
			UIDropDownMenu_Initialize(Forgetful_dd_2, Forgetful_Dropdown_Initialise)
			Forgetful_DS_Main:Show()	-- show the main window		
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
		
	FGDS.UpdateIcons()	--refresh the spec icons before the panel opens up
	UIDropDownMenu_Initialize(Forgetful_dd_1, Forgetful_Dropdown_Initialise)	--initialise the two drop down boxes
	UIDropDownMenu_Initialize(Forgetful_dd_2, Forgetful_Dropdown_Initialise)
	Forgetful_DS_Main:Show()	-- show the main window

end

--registering slash commands is quite picky about program location, best left here
SLASH_FORGETFUL1 = "/forgetful"
SLASH_FORGETFUL2 = "/forget"
SLASH_FORGETFUL2 = "/fg"

SlashCmdList["FORGETFUL"] = FGDS.SlashHandler


 --[[====================================================
	Name: FGDS.UpdateIcons()
		Description: updates the spec icons in the frame before the panel is opened
		Returns: Nothing
		Parameters: None
	
		Notes:
====================================================--]]
function FGDS.UpdateIcons()

	if(GetActiveSpecGroup() == 1) then
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 1))
		
		Forgetful_DS_Main_Spec1_Icon:SetTexture(iconTexture, false)
		spec1 = name
		
		
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 2));
		Forgetful_DS_Main_Spec2_Icon:SetTexture(iconTexture, false)
		spec2 = name
		
		return
	end
	
	if(GetActiveSpecGroup() == 2) then
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 2));
		
		Forgetful_DS_Main_Spec2_Icon:SetTexture(iconTexture, false)
		spec2 = name
			
			
		local id, name, description, iconTexture, background, role = GetSpecializationInfo(GetSpecialization(false, false, 1));		
		Forgetful_DS_Main_Spec1_Icon:SetTexture(iconTexture, false)
		spec1 = name
	end

end


 --[[====================================================
	Name: FGDS.DropdownInitialise(self, level)
		Description: initialised the dropdown/comboboxes
		Returns: Nothing
		Parameters:
			self	: 	a reference to the dropdown box being initialised
			level	: 	the internal level of this dropdown box
	
		Notes:
====================================================--]]
function FGDS.DropdownInitialise(self, level)

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
			item.func = FGDS.DropdownOnClick
			
			UIDropDownMenu_AddButton(item)
			item = nil
		end
			
		--add a 'none' selection at the end
		item = UIDropDownMenu_CreateInfo()
		item.text = "None"
		item.value = "None"
		item.name = "none"
		item.func = FGDS.DropdownOnClick
		
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
			item.func = FGDS.DropdownOnClick2
			
			UIDropDownMenu_AddButton(item)
			item = nil
		end


		item = UIDropDownMenu_CreateInfo()
		item.text = "None"
		item.value = "None"
		item.name = "none"
		item.func = FGDS.DropdownOnClick
		
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
	Name: FGDS.DropdownOnClick(self)
		Description: the function called when any dropdown item is clicked in the first dropdown
		Returns: Nothing
		Parameters:
			self	: 	a reference to the item in the dropdown that was clicked
	
		Notes:
====================================================--]]
function FGDS.DropdownOnClick(self)

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
	Name: FGDS.DropdownOnClick2(self)
		Description: the function called when any dropdown item is clicked in the second dropdown
		Returns: Nothing
		Parameters:
			self	: 	a reference to the item in the dropdown that was clicked
	
		Notes:
====================================================--]]
function FGDS.DropdownOnClick2(self)

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
	Name: FGDS.LoadInterface()
		Description: creation of interface features and parts
		Returns: Nothing
		Parameters: None
	
		Notes:
====================================================--]]
function FGDS.LoadInterface()

	--building up the first drop down
	if(not Forgetful_dd_1) then
		CreateFrame("Button", "Forgetful_dd_1", Forgetful_DS_Main, "UIDropDownMenuTemplate")
	end
	
	Forgetful_dd_1:SetParent(Forgetful_DS_Main)	--parenting it to the frame
	Forgetful_dd_1:Show()
	Forgetful_dd_1:SetPoint("TOPRIGHT", -50, -75)
	Forgetful_dd_1:SetID(1)
	
	--initialising a dropdown box and setting it up
	UIDropDownMenu_Initialize(Forgetful_dd_1, FGDS.DropdownInitialise)
	UIDropDownMenu_SetWidth(Forgetful_dd_1, 110);
	UIDropDownMenu_SetButtonWidth(Forgetful_dd_1, 124)
	UIDropDownMenu_JustifyText(Forgetful_dd_1, "LEFT")
	
	--second dropdown building now;
	if(not Forgetful_dd_2) then
		CreateFrame("Button", "Forgetful_dd_2", Forgetful_DS_Main, "UIDropDownMenuTemplate")
	end
	
	Forgetful_dd_2:SetParent(Forgetful_DS_Main)	
	Forgetful_dd_2:Show()
	Forgetful_dd_2:SetPoint("TOPRIGHT", -50, -155)
	Forgetful_dd_2:SetID(2)
	
	UIDropDownMenu_Initialize(Forgetful_dd_2, FGDS.DropdownInitialise)
	UIDropDownMenu_SetWidth(Forgetful_dd_2, 110);
	UIDropDownMenu_SetButtonWidth(Forgetful_dd_2, 124)
	UIDropDownMenu_JustifyText(Forgetful_dd_2, "LEFT")

	
	--additions to the interface
	
	-- setup portrait texture, taken from the blizzard portrait code
	local _, class = UnitClass("player");
	Forgetful_DS_MainPortrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
	Forgetful_DS_MainPortrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[strupper(class)]));
	
	
	--the title
	Forgetful_DS_MainTitleText:SetText("Forgetful");
	
	--use helms checkbox
	local cbox = CreateFrame("CheckButton", "FG_DS_Cbox_UseHelms", Forgetful_DS_Main, "ChatConfigCheckButtonTemplate");
	cbox:SetPoint("TOPLEFT", 60, -35);
	_G[cbox:GetName() .. "Text"]:SetText("Change helm visibility with spec");	
			
	cbox:SetScript("OnClick", function(self, button, down) 
									if(self:GetChecked() == 1) then
										FG_DS_SETHELMS = true;
										_G["FG_DS_Cbox_Helm1"]:Show();
										_G["FG_DS_Cbox_Helm2"]:Show();
									else
										FG_DS_SETHELMS = false;
										_G["FG_DS_Cbox_Helm1"]:Hide();
										_G["FG_DS_Cbox_Helm2"]:Hide();
									end
								end )

									--use helms checkbox
	cbox = CreateFrame("CheckButton", "FG_DS_Cbox_Helm1", Forgetful_DS_Main, "ChatConfigCheckButtonTemplate");
	cbox:SetPoint("TOPLEFT", 210, -102);
	_G[cbox:GetName() .. "Text"]:SetText("Show Helm");	
			
	cbox:SetScript("OnClick", function(self, button, down) 
									if(self:GetChecked() == 1) then
										FG_DS_HH1 = true;
									else
										FG_DS_HH1 = false;
									end
								end )
	
	if(FG_DS_SETHELMS == false) then
		cbox:Hide();
	end
	
	--use helms checkbox
	cbox = CreateFrame("CheckButton", "FG_DS_Cbox_Helm2", Forgetful_DS_Main, "ChatConfigCheckButtonTemplate");
	cbox:SetPoint("TOPLEFT", 210, -181);
	_G[cbox:GetName() .. "Text"]:SetText("Show Helm");	
			
	cbox:SetScript("OnClick", function(self, button, down) 
									if(self:GetChecked() == 1) then
										FG_DS_HH2 = true;
									else
										FG_DS_HH2 = false;
									end
								end )
					
	if(FG_DS_SETHELMS == false) then
		cbox:Hide();
	end
end

function FGDS.SetHelm(spec_)

	if(FG_DS_SETHELMS == true) then
		if(spec_ == 1) then
			if(FG_DS_HH1 == true) then
				ShowHelm(true);
			else
				ShowHelm(false);
			end
		else
			if(FG_DS_HH2 == true) then
				ShowHelm(true);
			else
				ShowHelm(false);
			end		
		end
	end
	
	

end

local waitTable = {};
local waitFrame = nil;

function FGDS.Wait(delay, func, ...)
	
	--make sure we get a function and a number
	if(type(delay) ~= "number" or type(func) ~= "function") then
		return false;
	end
	
	--create a frame to use with onUpdate to get elapsed time
	if(waitFrame == nil) then
		waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
		waitFrame:SetScript("onUpdate",function (self,elapse)
		
			local count = #waitTable;
			local i = 1;
			
			while(i <= count) do
				local waitRecord = tremove(waitTable,i);
				local d = tremove(waitRecord,1);
				local f = tremove(waitRecord,1);
				local p = tremove(waitRecord,1);
				
				--anything passed it's elapsed time?
				if(d > elapse) then
					tinsert(waitTable,i,{d-elapse,f,p});
					i = i + 1;
				else
					count = count - 1;
					f(unpack(p));
				end
			end
		end);
	end
  
	tinsert(waitTable,{delay,func,{...}});
	return true;
end



