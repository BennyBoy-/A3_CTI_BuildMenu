//--- Used to create the root menu
CTI_Coin_CreateRootMenu = {
	params["_source"];
	private ["_categories"];
	
	_categories = switch (_source) do {
		case "HQ": {
			[
				["CTI_COIN_Items_0", "CTI_COIN_Items_1"],
				["Base", "Defenses"],
				[true, true]
			]
		};
		default {[]};
	};
	
	if (count _categories > 0) then {
		["Construction Menu", "CTI_COIN_Categories", _categories, "#USER:%1_0", ""] call BIS_FNC_createmenu; 
		[_categories select 0] call CTI_Coin_LoadSubMenu;
	};
	
	[_categories select 0]
};

//--- Used to create the root submenus
CTI_Coin_LoadSubMenu = {
	params["_categories"];

	//--- Load the structures if needed
	if ("CTI_COIN_Items_0" in _categories) then {
		_items = [];
		_itemEnabled = [];
		_itemVariable = [];
		
		_supply = (CTI_P_SideJoined) call CTI_CO_FNC_GetSideSupply;
		
		{
			_info = missionNamespace getVariable _x;
			_items pushBack format["%1  -  S%2", (_info select 0) select 1, _info select 2];
			_itemEnabled pushBack (if (_supply >= _info select 2) then {1} else {0});
			_itemVariable pushBack _x;
		} forEach (missionNamespace getVariable format ["CTI_%1_STRUCTURES", CTI_P_SideJoined]);
		
		["Base", "CTI_COIN_Items_0", [_itemVariable, _items, _itemEnabled], "", "missionNamespace setVariable ['CTI_COIN_PARAM', %1]; missionNamespace setVariable ['CTI_COIN_PARAM_KIND', 'STRUCTURES']; missionNamespace setVariable ['CTI_COIN_MENU', commandingMenu]"] call BIS_FNC_createmenu;
	};
	
	//--- Load the defenses if needed
	if ("CTI_COIN_Items_1" in _categories) then {
		//--- Load the defenses categories
		_items = [];
		_itemEnabled = [];
		_itemVariable = [];
		
		_funds = call CTI_CL_FNC_GetPlayerFunds;
		
		{
			_category = (missionNamespace getVariable "CTI_COIN_DEFENSE_CATEGORIES") select _x;
			_items pushBack _category;
			_itemVariable pushBack _x;
			_itemEnabled pushBack true;
			
			//--- Load the Menu for that category
			_sub_items = [];
			_sub_itemEnabled = [];
			_sub_itemVariable = [];
			{
				_info = missionNamespace getVariable _x;
				_sub_items pushBack format["%1  -  $%2", _info select 0, _info select 2];
				_sub_itemEnabled pushBack (if (_funds >= _info select 2) then {1} else {0});
				_sub_itemVariable pushBack _x;
			} forEach (missionNamespace getVariable format["CTI_COIN_DEFENSE_CATEGORY_%1", _x]);
			
			[_category, format["CTI_COIN_SubItem_%1", _x], [_sub_itemVariable, _sub_items, _sub_itemEnabled], "", "missionNamespace setVariable ['CTI_COIN_PARAM', %1]; missionNamespace setVariable ['CTI_COIN_PARAM_KIND', 'DEFENSES']; missionNamespace setVariable ['CTI_COIN_MENU', commandingMenu]"] call BIS_FNC_createmenu;
		} forEach (missionNamespace getVariable "CTI_COIN_DEFENSE_CATEGORIES_INDEX");
		
		["Defenses", "CTI_COIN_Items_1", [_itemVariable, _items, _itemEnabled], "#USER:CTI_COIN_SubItem_%1_0", ""] call BIS_FNC_createmenu;
	};
};

//--- Display EH: MouseZChanged (Scrolling), rotate a building while in preview mode
CTI_Coin_OnMouseZChanged = {
	with missionNamespace do {
		if !(isNil "CTI_COIN_PREVIEW") then {
			_ctrl = (29 in CTI_COIN_KEYS) || (157 in CTI_COIN_KEYS);
			_shift = (42 in CTI_COIN_KEYS) || (54 in CTI_COIN_KEYS);
			_alt = (56 in CTI_COIN_KEYS);
			
			_angle = 5;
			
			if (_shift) then {
				_angle = 10;
			} else {
				if (_alt) then {
					_angle = 20;
				} else {
					if (_ctrl) then {_angle = 1};
				};
			};
			
			if (_this < 0) then {_angle = -_angle};
			
			CTI_COIN_DIR = (direction CTI_COIN_PREVIEW) + _angle;
			CTI_COIN_PREVIEW setDir CTI_COIN_DIR;
		};
	};
};

CTI_Coin_OnMouseButtonDown = {
	with missionNamespace do {
		if !(isNil 'CTI_COIN_PREVIEW') then {
			call CTI_Coin_OnPreviewPlacement;
		};
	};
};

//--- A structure or defense preview is placed down
CTI_Coin_OnPreviewPlacement = {
	with missionNamespace do {
		_item = objNull;//debug
		switch (CTI_COIN_PARAM_KIND) do {
			case 'STRUCTURES': {
				_item = (CTI_COIN_PARAM select 1) select 0;
			};
			case 'DEFENSES': {
				_item = CTI_COIN_PARAM select 1;
			};
		};
		
		_direction = direction CTI_COIN_PREVIEW;
		_position = position CTI_COIN_PREVIEW;
		
		deleteVehicle CTI_COIN_PREVIEW;
		CTI_COIN_PARAM = nil;
		CTI_COIN_PREVIEW = nil;
		
		//--- Remove the description overlay content
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlSetStructuredText (parseText "");
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlCommit 0;
		
		_placed_item = _item createVehicle _position;
		_placed_item setDir _direction;
		_placed_item setPos _position;
		_placed_item setDir _direction;
		_placed_item setVectorUp [0,0,0];
		
		CTI_COIN_LASTDIR = _direction;
		
		//--- Show the last known menu or the root menu again
		showCommandingMenu (missionNamespace getVariable ["CTI_COIN_MENU", "#USER:CTI_COIN_Categories_0"]);
	};
};

//--- Display EH: KeyDown, a key has been pressed (and is still being pressed)
CTI_Coin_OnKeyDown = {
	_key = _this select 1;
	_shift = _this select 2;
	_ctrl = _this select 3;
	_alt = _this select 4;
	
	_handled = false;
	with missionNamespace do {
		CTI_COIN_KEYS pushBack _key;
	
		
		switch (true) do {
			// case (_key in [1,14]): { //--- Either exit the camera or cancel the preview depending on where the player's at in the menu
			case (_key == 1 || _key in actionKeys "NavigateMenu"): { //--- Either exit the camera or cancel the preview depending on where the player's at in the menu
				_handled = true;
				if !(isNil 'CTI_COIN_PREVIEW') then {
					deleteVehicle CTI_COIN_PREVIEW;
					CTI_COIN_PARAM = nil;
					CTI_COIN_PREVIEW = nil;
					
					//--- Remove the description overlay content
					((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlSetStructuredText (parseText "");
					((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlCommit 0;
					
					//--- Show the last known menu or the root menu again
					showCommandingMenu (missionNamespace getVariable ["CTI_COIN_MENU", "#USER:CTI_COIN_Categories_0"]);
				} else {
					// if (_key == 14 && commandingMenu != "#USER:CTI_COIN_Categories_0") then {_handled = false} else {CTI_COIN_EXIT = true};
					if (_key in actionKeys "NavigateMenu" && commandingMenu != "#USER:CTI_COIN_Categories_0") then {_handled = false} else {CTI_COIN_EXIT = true};
				};
			};
			case (_key in [28, 156]): {if !(isNil 'CTI_COIN_PREVIEW') then {call CTI_Coin_OnPreviewPlacement}};
		};
	};
	
	_handled
};

//--- Display EH: KeyUp, a key press has been released
CTI_Coin_OnKeyUp = {
	_key = _this select 1;
	_shift = _this select 2;
	_ctrl = _this select 3;
	_alt = _this select 4;
	
	with missionNamespace do {
		CTI_COIN_KEYS = CTI_COIN_KEYS - [_key];
	};
	
	false;
};