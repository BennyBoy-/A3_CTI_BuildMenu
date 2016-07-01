// Parameter(s): createmenu
		// _this select 0 - STRING or ARRAY - Name of menu or [Name, Context sensitive]
		// _this select 1 - STRING - Variable in which will be menu params stored (as variable_0, variable_1, ...)
		// _this select 2 - ARRAY - Array with menu items (can be either [items] or [[items],[itemNames],[itemEnable]] if you want to set custom params (names, enable values))
		// _this select 3 - STRING - Name of submenu which will open when item is activated. Name of selected item is passed to string as %1
		// _this select 4 - STRING - Expression which is executed when item is activated. Name of selected item is passed to string as %1, ID is %2.
		// _this select 5 - ANYTHING (Optional) - params passed to expression. Whole argument is passed as %3
		// _this select 6 - BOOLEAN - False to hide number shortcuts

//--- Global
CTI_COIN_AREA_SIZE = [200, 40];

//--- 
//--- Param
_startPos = getPos player;
_source = 'HQ';

if !(isNil {missionNamespace getVariable "CTI_COIN_CAMCONSTRUCT"}) exitWith {};

112200 cutRsc ["CTI_ConstructionInterface", "plain"]; 
uiNamespace setVariable ["CTI_COIN_DISPLAY", finddisplay 46];

//--- Initialize some variables and create the construction camera
with missionNamespace do {
	//--- Wipe the previous variables just in case
	CTI_COIN_EXIT = false;
	CTI_COIN_KEYS = [];
	CTI_COIN_MENU = nil;
	CTI_COIN_PARAM = nil;
	CTI_COIN_PARAM_KIND = nil;
	CTI_COIN_PREVIEW = nil;
	CTI_COIN_LASTFUNDS = [0,0];

	//--- Create the construction camera
	CTI_COIN_CAMCONSTRUCT = "camconstruct" camCreate [position player select 0,position player select 1,15];
	CTI_COIN_CAMCONSTRUCT cameraEffect ["internal","back"];
	CTI_COIN_CAMCONSTRUCT camPrepareFov 0.900;
	CTI_COIN_CAMCONSTRUCT camPrepareFocus [-1,-1];
	CTI_COIN_CAMCONSTRUCT camCommitPrepared 0;
	cameraEffectEnableHUD true;
	CTI_COIN_CAMCONSTRUCT setdir direction player;
	[CTI_COIN_CAMCONSTRUCT, -30, 0] call BIS_fnc_setPitchBank;
	CTI_COIN_CAMCONSTRUCT camConstuctionSetParams ([_startPos] + CTI_COIN_AREA_SIZE);
	
	//--- We add the Display EH which the camera use
	CTI_COIN_DISPLAYEH_KEYDOWN = (uiNamespace getVariable "CTI_COIN_DISPLAY") displayAddEventHandler ["KeyDown", {(_this) call CTI_Coin_OnKeyDown}];
	CTI_COIN_DISPLAYEH_KEYUP = (uiNamespace getVariable "CTI_COIN_DISPLAY") displayAddEventHandler ["KeyUp", {(_this) call CTI_Coin_OnKeyUp}];
	CTI_COIN_DISPLAYEH_MOUSESCROLL = (uiNamespace getVariable "CTI_COIN_DISPLAY") displayAddEventHandler ["MouseZChanged", {(_this select 1) spawn CTI_Coin_OnMouseZChanged}];
	CTI_COIN_DISPLAYEH_MOUSECLICK = (uiNamespace getVariable "CTI_COIN_DISPLAY") displayAddEventHandler ["MouseButtonDown", {(_this) spawn CTI_Coin_OnMouseButtonDown}];
};

showCinemaBorder false;

//--- Load up the initial menu
_categories = _source call CTI_Coin_CreateRootMenu;

showCommandingMenu "#USER:CTI_COIN_Categories_0";
_last_collision_update = -100;

with missionNamespace do {
	while {!isNil 'CTI_COIN_CAMCONSTRUCT' && !CTI_COIN_EXIT} do {
		//--- Parameters are set, a preview is being created or is being moved
		if !(isNil 'CTI_COIN_PARAM') then {
			if (isNil 'CTI_COIN_PREVIEW') then {
				_label = "";
				_preview = objNull;
				switch (CTI_COIN_PARAM_KIND) do {
					case 'STRUCTURES': {
						_label = (CTI_COIN_PARAM select 0) select 1;
						_preview = (CTI_COIN_PARAM select 1) select 0;
					};
					case 'DEFENSES': {
						_label = CTI_COIN_PARAM select 0;
						_preview = CTI_COIN_PARAM select 1;
					};
				};
				
				//--- Create the preview item
				_preview_item = _preview createVehicleLocal (screenToWorld [0.5,0.5]);
				_preview_item allowDamage false;
				if !(isNil 'CTI_COIN_LASTDIR') then {_preview_item setDir CTI_COIN_LASTDIR};
				CTI_COIN_DIR = getDir _preview_item;
				
				//--- Update the overlay description
				_textHint =  format ["<t align='center'><t size='1.4'>%1</t><br /><t size='1'></t></t>", _label];
				((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlSetStructuredText (parseText _textHint);
				((uiNamespace getVariable "cti_title_coin") displayCtrl 112214) ctrlCommit 0;
				
				//--- Attach the preview item to the camera
				CTI_COIN_CAMCONSTRUCT camSetTarget _preview_item;
				CTI_COIN_CAMCONSTRUCT camCommit 0;
				CTI_COIN_PREVIEW = _preview_item;
			} else {
				CTI_COIN_PREVIEW setDir CTI_COIN_DIR;
				CTI_COIN_PREVIEW setVectorUp [0,0,0];
				if (time - _last_collision_update > 2) then {_last_collision_update = time;{CTI_COIN_PREVIEW disableCollisionWith _x} forEach (CTI_COIN_PREVIEW nearEntities 150)};
			};
		} else { //--- The player's commanding menu is gone (parent hierarchy is lost on menu refresh)
			if (commandingMenu == '') then {
				showCommandingMenu '#USER:CTI_COIN_Categories_0';
			};
		};
		
		//--- Check if the funds overlay control need an update
		_update = false;
		if (_source == 'HQ') then {
			if ((CTI_P_SideJoined call CTI_CO_FNC_GetSideSupply) != (CTI_COIN_LASTFUNDS select 0)) then {_update = true};
			if ((call CTI_CL_FNC_GetPlayerFunds) != (CTI_COIN_LASTFUNDS select 1)) then {_update = true};
			CTI_COIN_LASTFUNDS set [0, CTI_P_SideJoined call CTI_CO_FNC_GetSideSupply];
			CTI_COIN_LASTFUNDS set [1, call CTI_CL_FNC_GetPlayerFunds];
		} else {
			if ((call CTI_CL_FNC_GetPlayerFunds) != (CTI_COIN_LASTFUNDS select 1)) then {_update = true};
			CTI_COIN_LASTFUNDS set [1, call CTI_CL_FNC_GetPlayerFunds];
		};
		
		//--- Update the overlay control if needed along with the current menu
		if (_update) then {
			//--- Since the cash changed, we have to reload the commanding menus
			(_categories) call CTI_Coin_LoadSubMenu;
			showCommandingMenu commandingMenu;
			
			//--- Update the overlay cash controls
			_cashValues = "";
			_cashSize = 2;
			if (_source == 'HQ') then {
				_cashValues = _cashValues + format ["S %1<br />", CTI_P_SideJoined call CTI_CO_FNC_GetSideSupply];
				_cashValues = _cashValues + format ["$ %1<br />", call CTI_CL_FNC_GetPlayerFunds];
				_cashSize = 1.4;
			} else {
				_cashValues = _cashValues + format ["$ %1<br />", call CTI_CL_FNC_GetPlayerFunds];
			};
			
			_cashText = format ["<t color='#42b6ff' shadow='2' size='%1' align='left' valign='middle'>%2</t>", _cashSize, _cashValues];
			((uiNamespace getVariable "cti_title_coin") displayCtrl 112224) ctrlSetStructuredText (parseText _cashText);
			((uiNamespace getVariable "cti_title_coin") displayCtrl 112224) ctrlCommit 0;
		};
		
		//--- Check if the controls overlay need an update
		// CloseContext -> rmb
		// NavigateMenu -> backspace
		
		sleep .01;
	};
};

//--- Cleanup
with missionNamespace do {
	//--- Cleanup the preview if needed
	if !(isNil 'CTI_COIN_PREVIEW') then {deleteVehicle CTI_COIN_PREVIEW};
	
	//--- Remove the Construction Overlay
	112200 cutText ["", "plain"];
	
	//--- Remove the menu
	showCommandingMenu '';
	
	//--- We add the Display EH which the camera use
	(uiNamespace getVariable "CTI_COIN_DISPLAY") displayRemoveEventHandler ["KeyDown", CTI_COIN_DISPLAYEH_KEYDOWN];
	(uiNamespace getVariable "CTI_COIN_DISPLAY") displayRemoveEventHandler ["KeyUp", CTI_COIN_DISPLAYEH_KEYUP];
	(uiNamespace getVariable "CTI_COIN_DISPLAY") displayRemoveEventHandler ["MouseZChanged", CTI_COIN_DISPLAYEH_MOUSESCROLL];
	(uiNamespace getVariable "CTI_COIN_DISPLAY") displayRemoveEventHandler ["MouseButtonDown", CTI_COIN_DISPLAYEH_MOUSECLICK];

	//--- We remove the camera
	if !(isNil 'CTI_COIN_CAMCONSTRUCT') then {
		CTI_COIN_CAMCONSTRUCT cameraEffect ["terminate","back"];
		camDestroy CTI_COIN_CAMCONSTRUCT;
	};
	
	CTI_COIN_CAMCONSTRUCT = nil;
};