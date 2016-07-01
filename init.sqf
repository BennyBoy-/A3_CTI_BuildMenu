// _v			= ["Headquarters"];
// _n			= [EASTHQ];
// _d			= [getText (configFile >> "CfgVehicles" >> (_n select (count _n - 1)) >> "displayName")];
// _c			= [('WFBE_HQDEPLOYPRICE' Call GetNamespace)];
// _t			= [if (WF_Debug) then {1} else {30}];
// _s			= ["HQSite"];
// _dis		= [15];
// _dir		= [0];

// for [{_count = count _v - 1},{_count >= 0},{_count = _count - 1}] do {
	// [Format["WFBE_EAST%1TYPE",_v select _count],_count,true] Call SetNamespace;
// };
CTI_P_SideJoined = side player;
call compile preprocessFileLineNumbers "cti\Init_CommonConstants.sqf";
CTI_CL_FNC_GetPlayerFunds = compile preprocessFileLineNumbers "cti\Client_GetPlayerFunds.sqf";
CTI_CO_FNC_GetSideSupply = compile preprocessFileLineNumbers "cti\Common_GetSideSupply.sqf";
call compile preprocessFileLineNumbers "coin_func.sqf";
(west) call compile preprocessFileLineNumbers "cti\base_west.sqf";

//--- Move to set defense / adapt
_side = CTI_P_SideJoined; ///dbg

//--- Retrieve Categories
_sub_categories = [];
_sub_categories_index = [];

_index = 0;
{
	_info = missionNamespace getVariable _x;
	if !((_info select 3) in _sub_categories) then {
		_sub_categories pushBack (_info select 3);
		_sub_categories_index pushBack _index;
		_index = _index + 1;
	};
	
	_find = _sub_categories find (_info select 3);
	missionNamespace setVariable [format["CTI_COIN_DEFENSE_CATEGORY_%1", _find], (missionNamespace getVariable [format["CTI_COIN_DEFENSE_CATEGORY_%1", _find], []]) + [_x]];
} forEach (missionNamespace getVariable format ["CTI_%1_DEFENSES", _side]);

missionNamespace setVariable ["CTI_COIN_DEFENSE_CATEGORIES", _sub_categories];
missionNamespace setVariable ["CTI_COIN_DEFENSE_CATEGORIES_INDEX", _sub_categories_index];