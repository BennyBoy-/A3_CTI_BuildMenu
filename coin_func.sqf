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

//--- Update the preview's label
CTI_Coin_UpdateItemLabel = {
	private["_color", "_label", "_textHint"];
	
	_color = _this;
	
	with missionNamespace do {
		
		_label = switch (CTI_COIN_PARAM_KIND) do {
			case 'STRUCTURES': {(CTI_COIN_PARAM select 0) select 1};
			case 'DEFENSES': {CTI_COIN_PARAM select 0};
			default {""};
		};
		
		//--- Update the overlay description
		_textHint =  format ["<t align='center'><t size='1.4' color='%2'>%1</t><br /><t size='1'></t></t>", _label, _color];
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlSetStructuredText (parseText _textHint);
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlCommit 0;
	};
};

//--- Update the preview's lifespan
CTI_Coin_UpdatePreview = {
	private ["_color", "_preview"];
	
	_preview = _this;
	
	with missionNamespace do {
		_color = CTI_COIN_COLOR_VALID;
		
		if (_preview distance CTI_COIN_SOURCE > CTI_COIN_RANGE) then { //--- Out of boundaries, apply grey
			_color = CTI_COIN_COLOR_OUTOFRANGE;
		} else { //--- In boundaries, check for obstruction
			if !(_preview call CTI_Coin_PreviewSurfaceIsValid) then {
				_color = CTI_COIN_COLOR_INVALID;
			};
		};
		
		//--- Show or hide the object depending on the boundary presence
		// if (_color == CTI_COIN_COLOR_OUTOFRANGE && !isObjectHidden _preview) then {_preview hideObject true};
		// if (_color != CTI_COIN_COLOR_OUTOFRANGE && isObjectHidden _preview) then {_preview hideObject false};
		
		//--- Get the matching UI color
		_colorUI = switch (_color) do {
			case CTI_COIN_COLOR_INVALID: {CTI_COIN_COLOR_INVALID_UI};
			case CTI_COIN_COLOR_OUTOFRANGE: {CTI_COIN_COLOR_OUTOFRANGE_UI};
			case CTI_COIN_COLOR_VALID: {CTI_COIN_COLOR_VALID_UI};
			default {CTI_COIN_COLOR_OUTOFRANGE_UI};
		};
		
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112201) ctrlSetTextColor _colorUI;
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112201) ctrlCommit 0;
		
		//--- Update the Centered description color with the matching color
		(_color) call CTI_Coin_UpdateItemLabel;
	};
};

CTI_Coin_PreviewSurfaceIsValid = {
	private ["_isValid", "_preview"];
	
	_preview = _this;
	
	_isValid = true;
	
	with missionNamespace do {
		if (surfaceIsWater position _preview) then {
			_isValid = false
		} else {
			if (count((position _preview) nearEntities [['Man','Car','Motorcycle','Tank','Air','Ship'], 10]) > 0) then {
				_isValid = false
			} else {
				if (CTI_COIN_PARAM_KIND == "STRUCTURES") then {
					_maxGrad = 24;
					_minDist = 20;
					
					_isFlat = (position _preview) isFlatEmpty [
						(sizeof typeof _preview) / _minDist, 	//--- Minimal distance from another object
						0, 										//--- If 0, just check position. If >0, select new one
						_maxGrad, 								//--- Max gradient
						(sizeof typeof _preview), 				//--- Gradient area
						0, 										//--- 0 for restricted water, 2 for required water,
						false, 									//--- True if some water can be in 25m radius
						_preview 								//--- Ignored object
					];
					
					if (count _isFlat == 0) then {_isValid = false};
				};
			};
		};
	};
	
	_isValid
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

//--- Display EH: The LMB or RMB is clicked down
CTI_Coin_OnMouseButtonDown = {
	private["_button"];
	
	_button = _this select 1;
	
	with missionNamespace do {
		switch (_button) do {
			case 0: {
				if !(isNil 'CTI_COIN_PREVIEW') then {
					call CTI_Coin_OnPreviewPlacement;
				};
			};
			case 1: {
				if !(isNil 'CTI_COIN_PREVIEW') then {
					call CTI_Coin_OnPreviewCanceled;
				} else {
					if (commandingMenu == "#USER:CTI_COIN_Categories_0") then {CTI_COIN_EXIT = true};
				};
			};
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
		
		if (CTI_COIN_PREVIEW call CTI_Coin_PreviewSurfaceIsValid) then { //--- Last check to make sure that the position is valid
			deleteVehicle CTI_COIN_PREVIEW;
			CTI_COIN_PARAM = nil;
			CTI_COIN_PREVIEW = nil;
			
			//--- Remove the description overlay content
			((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlSetStructuredText (parseText "");
			((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlCommit 0;
			
			//--- Reset the selector to default
			((uiNamespace getVariable "cti_title_coin") displayCtrl 112201) ctrlSetTextColor CTI_COIN_COLOR_OUTOFRANGE_UI;
			((uiNamespace getVariable "cti_title_coin") displayCtrl 112201) ctrlCommit 0;
			
			//--- Create the desired item
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
};

//--- The structure preview is canceled
CTI_Coin_OnPreviewCanceled = {
	with missionNamespace do {
		deleteVehicle CTI_COIN_PREVIEW;
		CTI_COIN_PARAM = nil;
		CTI_COIN_PREVIEW = nil;
		
		//--- Remove the description overlay content
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlSetStructuredText (parseText "");
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlCommit 0;
		
		//--- Reset the selector to default
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112201) ctrlSetTextColor CTI_COIN_COLOR_OUTOFRANGE_UI;
		((uiNamespace getVariable "cti_title_coin") displayCtrl 112201) ctrlCommit 0;
		
		//--- Show the last known menu or the root menu again if nil
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
					call CTI_Coin_OnPreviewCanceled;
				} else {
					// if (_key == 14 && commandingMenu != "#USER:CTI_COIN_Categories_0") then {_handled = false} else {CTI_COIN_EXIT = true};
					if (_key in actionKeys "NavigateMenu" && commandingMenu != "#USER:CTI_COIN_Categories_0") then {_handled = false} else {CTI_COIN_EXIT = true};
				};
			};
			case (_key in [28, 156]): {if !(isNil 'CTI_COIN_PREVIEW') then {call CTI_Coin_OnPreviewPlacement}};
			case (_key in actionKeys "Diary"): {profileNamespace setVariable ["CTI_COIN_WALLALIGN", !(profileNamespace getVariable ["CTI_COIN_WALLALIGN", true])]};
			case (_key in actionKeys "Gear"): {profileNamespace setVariable ["CTI_COIN_AUTODEFENSE", !(profileNamespace getVariable ["CTI_COIN_AUTODEFENSE", true])]};
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