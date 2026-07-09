//Main function used to call the correct function for spawning entities of all types

#include "macros.inc"

private[ "_obj" ];
params[ "_cfg", [ "_info", grpNull ], "_ctx" ]; //INFO is usually a group but is also used by triggers as a defered boolean flag

private _ids = _ctx get "ids";

private _id = getNumber( _cfg >> 'id' );

if ( count _ids <= _id ) then {
	_ids resize _id;
};

private _dataType = getText( _cfg >> "dataType" );

private _msg = format[ "spawning - %1 %2 - ID: %3", _dataType, getText( _cfg >> "type" ), _id ];

switch ( _dataType ) do {

	case "Group" : {
		_obj = [ _cfg, _ctx ] call LARs_fnc_spawnGroup;
		_msg = format[ "%1, GroupID %2", _msg, groupId _obj ];
	};

	case "Object" : {
		_obj = [ _cfg, _info, _ctx ] call LARs_fnc_spawnObject;
		if (vehicleVarName _obj isNotEqualTo "") then {
			_msg = format[ "%1, VarName %2", _msg, vehicleVarName _obj ];
		};
	};

	case "Trigger" : {
		_obj = [ _cfg, _info, _ctx ] call LARs_fnc_spawnTrigger;
		if (vehicleVarName _obj isNotEqualTo "") then {
			_msg = format[ "%1, VarName %2", _msg, vehicleVarName _obj ];
		};
	};

	case "Logic" : {
		_obj = [ _cfg, _ctx ] call LARs_fnc_spawnLogic;
		if (vehicleVarName _obj isNotEqualTo "") then {
			_msg = format[ "%1, VarName %2", _msg, vehicleVarName _obj ];
		};
	};

	case "Marker" : {
		_obj = [ _cfg, _ctx ] call LARs_fnc_spawnMarker;
		_msg = format[ "%1, Name %2", _msg, str _obj ];
	};

	case "Waypoint" : {
		_obj = [ _cfg, _info, _ctx ] call LARs_fnc_spawnWaypoint;
		if (waypointName _obj isNotEqualTo "") then {
			_msg = format[ "%1, WaypointID %2", _msg, waypointName _obj ];
		};
	};

	case "Layer" : {
		[ ( _cfg >> "Entities" ), _info, _ctx ] call LARs_fnc_spawnCompItems;
	};
};

if !( isNil	"_obj" ) then {
	_ids set [ _id, _obj ];
	if ( ( _obj isEqualType objNull ) && { !isNull _obj } ) then {
		[ _obj, _cfg ] call LARs_fnc_customAttributes;
	};
};

DEBUG_MSG(DEBUG,_msg);

