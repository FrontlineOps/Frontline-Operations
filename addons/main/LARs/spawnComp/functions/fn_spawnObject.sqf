
//Spawns an object from a composition

#include "macros.inc"

params[ "_cfg", "_group", "_ctx" ];

private _attributes = _cfg >> "Attributes";
private _inits = _ctx get "inits";

private _veh = objNull;
private _isFlying = false;
private _needsSurfaceUp = false;

private _presence = [ ( _attributes >> "presence" ), "NUM", 1 ] call LARs_fnc_getCfgValue;
private _preCondition = [ ( _attributes >> "presenceCondition" ), "TXT", "true" ] call LARs_fnc_getCfgValue; //TODO: does this need defering

if ( random 1 <= _presence && { call compile _preCondition } ) then {

	private _type = getText( _cfg >> "type" );
	private _ATLOffset = getNumber( _cfg >> "atlOffset" );
	private _isSimpleObject = [ ( _attributes >> "createAsSimpleObject" ), "BOOL", false ] call LARs_fnc_getCfgValue;

	switch ( true ) do {

		case ( _type isKindOf "Man" ) : {

			_veh = _group createUnit [ _type, [0,0,500], [], 0, "FORM" ];
			_veh enableSimulationGlobal false;

			private _skill = [ ( _attributes >> "skill" ), "NUM", -1 ] call LARs_fnc_getCfgValue;
			if ( _skill > -1 ) then {
				_veh setSkill _skill;
			};

			private _rank = [ ( _attributes >> "rank" ), "TXT", "" ] call LARs_fnc_getCfgValue;
			if (_rank isNotEqualTo "") then {
				_veh setRank _rank;
			};

			private _stance = [ ( _attributes >> "stance" ), "TXT", "" ] call LARs_fnc_getCfgValue;
			if (_stance isNotEqualTo "") then {
				_veh setUnitPos _stance;
			};

			private _ignoreTrigDynSym = [ ( _attributes >> "ignoreByDynSimulGrid" ), "BOOL", false ] call LARs_fnc_getCfgValue;
			_veh triggerDynamicSimulation _ignoreTrigDynSym;

			if ( isClass( _attributes >> "Inventory" ) ) then {
				[ _attributes >> "Inventory", _veh ] call LARs_fnc_getUnitInventory;
			};

		};

		case ( _type isKindOf "LandVehicle" ) : {

			if ( _isSimpleObject ) then {
				_veh = createSimpleObject [ _type, [0,0,500] ];
			}else{
				_veh = createVehicle [ _type, [0,0,500], [], 0, "CAN_COLLIDE" ];
				_veh enableSimulationGlobal false;
			};

			private _lock = [ ( _attributes >> "lock" ), "TXT", "" ] call LARs_fnc_getCfgValue;
			if (_lock isNotEqualTo "") then {
				_veh setVehicleLock _lock
			};

			private _fuel = [ ( _attributes >> "fuel" ), "NUM", 1 ] call LARs_fnc_getCfgValue;
			_veh setFuel _fuel;

			_needsSurfaceUp = true;

			private _aiRadarUsage = [ ( _attributes >> "aiRadarUsage" ), "NUM", 0 ] call LARs_fnc_getCfgValue;
			_veh setVehicleRadar _aiRadarUsage;
		};

		case ( _type isKindOf "Air" ) : {

			_isFlying = _ATLOffset > 18;

			if ( _isSimpleObject ) then {
				_veh = createSimpleObject [ _type, [0,0,500] ];
			}else{
				_veh = createVehicle [ _type, [0,0,500], [], 0, [ "NONE", "FLY" ] select _isFlying ];
				_veh enableSimulationGlobal false;
			};

			private _lock = [ ( _attributes >> "lock" ), "TXT", "" ] call LARs_fnc_getCfgValue;
			if (_lock isNotEqualTo "") then {
				_veh setVehicleLock _lock
			};

			private _fuel = [ ( _attributes >> "fuel" ), "NUM", 1 ] call LARs_fnc_getCfgValue;
			_veh setFuel _fuel;

			if ( !_isSimpleObject && { _isFlying } ) then {
				_veh engineOn true;
			}else{
				_needsSurfaceUp = !_isFlying;
			};

			private _aiRadarUsage = [ ( _attributes >> "aiRadarUsage" ), "NUM", 0 ] call LARs_fnc_getCfgValue;
			_veh setVehicleRadar _aiRadarUsage;

		};

		default {

			if ( _isSimpleObject ) then {
				_veh = createSimpleObject [ _type, [0,0,500] ];
			}else{
				_veh = createVehicle [ _type, [0,0,500], [], 0, "CAN_COLLIDE" ];
				_veh enableSimulationGlobal false;
			};
		};
	};

	if ( isNull _veh ) exitWith { objNull };

	if ( DEBUG_DEV ) then {
		[ _veh, [ 1, 0, 0, 1 ] ] call LARs_fnc_drawBounds;
	};

	private _health = [ ( _attributes >> "health" ), "NUM", 1 ] call LARs_fnc_getCfgValue;
	_veh setDamage ( 1 - _health );

	private _ammo = [ ( _attributes >> "ammo" ), "NUM", 1 ] call LARs_fnc_getCfgValue;
	_veh setVehicleAmmo _ammo;

	private _name = [ ( _attributes >> "name" ), "TXT", "" ] call LARs_fnc_getCfgValue;
	if (_name isNotEqualTo "") then {
		_veh setVehicleVarName _name;
		missionNamespace setVariable [ _name, _veh, true ];
	};

	private _description = [ ( _attributes >> "description" ), "TXT", "" ] call LARs_fnc_getCfgValue;
	if (_description isNotEqualTo "") then {
		//TODO: Can you set roleDescription ??
	};

	{
		_x params[ "_attribute", "_command" ];

		private _value = [ ( _attributes >> _attribute ), "BOOL", true ] call LARs_fnc_getCfgValue;
		_value call compile format[ "_veh %1 _this", _command ];
	}forEach [
		[ "reportRemoteTargets", "setVehicleReportRemoteTargets" ],
		[ "receiveRemoteTargets", "setVehicleReceiveRemoteTargets" ],
		[ "reportOwnPosition", "setVehicleReportOwnPosition" ]
	];


	private _texture = [ ( _attributes >> "textures" ), "TXT", "" ] call LARs_fnc_getCfgValue;
	if (_texture isNotEqualTo "") then {
		_veh setObjectTextureGlobal [ 0, _texture ];
	};

	private _position = getArray( _cfg >> "PositionInfo" >> "position" );
	private _rotation = [ ( _cfg >> "PositionInfo" >> "angles" ), "ARRAY", [0,0,0] ] call LARs_fnc_getCfgValue;
	private _randomStartPos = getArray( _cfg >> "randomStartPositions" );
	private _placementRadius = getNumber( _attributes >> "placementRadius" );

	_position = [ _veh, _position, _rotation, _ATLOffset, _randomStartPos, _needsSurfaceUp, _placementRadius, _ctx ] call LARs_fnc_setPositionAndRotation;

	if ( typeOf _veh isKindOf "Man" ) then {
		( waypoints ( group _veh )) select 0 setWaypointPosition [ getPos _veh, 0 ];
	};

	private _init = getText( _attributes >> "init" );
	if (_init isNotEqualTo "") then {
		_nul = _inits pushBack [ _veh, format[ "this = _this; %1", _init ] ];
	};

	//enable simulation if not marked as disabled
	_disableSimulation = [ ( _attributes >> "disableSimulation" ), "BOOL", false ] call LARs_fnc_getCfgValue;
	_veh enableSimulationGlobal !_disableSimulation;

};

_veh
