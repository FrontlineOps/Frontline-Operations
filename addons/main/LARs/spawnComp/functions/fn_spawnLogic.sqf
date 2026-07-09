
//Spawns a logic from a composition

private _logic = objNull;
params[ "_cfg", "_ctx" ];
private _inits = _ctx get "inits";

private _presence = [ ( _cfg >> "presence" ), "NUM", 1 ] call LARs_fnc_getCfgValue;
private _preCondition = [ ( _cfg >> "presenceCondition" ), "TXT", "true" ] call LARs_fnc_getCfgValue; //TODO: does this need defering

if ( random 1 <= _presence && { call compile _preCondition } ) then {

	private _type = getText( _cfg >> "type" );
	private _position = [ ( _cfg >> "PositionInfo" >> "position" ), "ARRAY", [0,0,0] ] call LARs_fnc_getCfgValue;
	private _ATLOffset = getNumber( _cfg >> "atlOffset" );
	private _rotation = [ ( _cfg >> "PositionInfo" >> "angles" ), "ARRAY", [0,0,0] ] call LARs_fnc_getCfgValue;
	private _varName = getText( _cfg >> "name" );

	//FIX: Seems to not to be saved in the composition ??
	//_placementRadius = getNumber( _cfg >> "Attributes" >> "placementRadius" );

	//TODO: Split logics into proper module grps
	//FIXED: module initialisation now handles groups for modules on side logic?? ( 1.86 )
	private _group = createGroup sideLogic;
	_logic = _group createUnit [ _type, [0,0,0], [], 0, "CAN_COLLIDE" ]; //No randomStart for logics

	//Handle initialisation of modules spawned at runtime( time > 0 ) ( A3 1.86 )
	if ( _type isKindOf "Module_F" ) then {
		_logic setVariable [ "BIS_fnc_initModules_disableAutoActivation", false ];
	};

	_position = [ _logic, _position, _rotation, _ATLOffset, [], false, 0, _ctx ] call LARs_fnc_setPositionAndRotation;

	if (_varName isNotEqualTo "") then {
		_logic setVehicleVarName _varName;
		missionNamespace setVariable [ _varName, _logic, true ];
	};

	private _init = getText( _cfg >> "init" );
	private _nul = _inits pushBack [ _logic, format[ "this = _this; %1", _init ] ];

};

_logic
