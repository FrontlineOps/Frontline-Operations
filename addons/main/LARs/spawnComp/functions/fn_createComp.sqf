//Main function resposible for spawning compositions

//[ COMP_NAME, POS_ATL, OFFSET, DIR, ALIGN_TERRAIN ] call LARs_fnc_spawnComp;

//COMP_NAME - Classname given to composition in missionConfigFile CfgCompositions

//POS_ATL( optional ) - Position to spawn composition
//	If not given or empty array passed then original saved composition position is used
//	Also accepts OBJECT, MARKER, LOCATION

//OFFSET( optional ) - ARRAY [ x, y, z ] ammount to offset composition, as a compositions base pos can vary from what you want when its saved

//DIR( optional ) - Direction to face composition in, If POS_ATL is of type OBJECT, MARKER, LOCATION passing TRUE for direction will use objects direction

//ALIGN_TERRAIN( optional ) - BOOL, Whether composition objects should align themselves to their positions surface normal

#include "macros.inc"

params[
	"_compName",
	[ "_compPos", [] ],
	[ "_compOffset", [0,0,0] ],
	[ "_compRot", 0 ],
	[ "_compAlign", true ],
	[ "_compWater", true ],
	[ "_compIgnoreATLOffset", false ]
];

_msg = format[ "COMP - Name: %1, Pos:%2, Offset: %3, Rot: %4, Align: %5", _compName, _compPos, _compOffset, _compRot, _compAlign ];
DEBUG_MSG(DEBUG,_msg);

private _compCfg = missionConfigFile >> "CfgCompositions" >> _compName;

//Get user OR compositions, position and direction
( [ _compCfg, _compPos, _compRot ] call LARs_fnc_getCompPosition ) params[ "_compPos", "_compRot", [ "_asPlaced", false ] ];


if ( DEBUG_DEV ) then {
	createVehicle [ "Sign_Arrow_Large_Green_F", _compPos, [], 0, "CAN_COLLIDE" ];
	_arrow = createVehicle [ "Sign_Arrow_Direction_Green_F", _compPos vectorAdd [ 0, 0, 3 ], [], 0, "CAN_COLLIDE" ];
	_arrow setDir _compRot;
};

//Arrays to store composition objects
private _groupCfgs = [];
private _itemCfgs = [];
private _deferedIDs = [];
private _deferedItems = [];
private _deferedGrps = [];
private _deferedTrgs = [];
private _crewLinks = [];
private _objects = [];
//The order objects are created in
private _priority = [ "Marker", "Object", "Group", "Waypoint", "Trigger", "Logic" ];
private _ids = [];
private _inits = [];

private _ctx = createHashMapFromArray [
	[ "compCfg", _compCfg ],
	[ "compPos", _compPos ],
	[ "compOffset", _compOffset ],
	[ "compRot", _compRot ],
	[ "compAlign", _compAlign ],
	[ "compWater", _compWater ],
	[ "compIgnoreATLOffset", _compIgnoreATLOffset ],
	[ "asPlaced", _asPlaced ],
	[ "groupCfgs", _groupCfgs ],
	[ "itemCfgs", _itemCfgs ],
	[ "deferedIDs", _deferedIDs ],
	[ "deferedItems", _deferedItems ],
	[ "deferedGrps", _deferedGrps ],
	[ "deferedTrgs", _deferedTrgs ],
	[ "crewLinks", _crewLinks ],
	[ "objects", _objects ],
	[ "priority", _priority ],
	[ "ids", _ids ],
	[ "inits", _inits ]
];

//Sort through composition items and assign as for spawning or defer
[ ( _compCfg >> "items" ), -1, configNull, false, _ctx ] call LARs_fnc_sortCfgItems;

//add all connections to deferedIDs
if ( isClass( _compCfg >> "connections" ) ) then {
	[ ( _compCfg >> "connections" ), _ctx ] call LARs_fnc_deferLinks;
};

//*****
//Main
//*****

DEBUG_MSG(DEBUG,"ITEMS");
private [ "_pType", "_dataType" ];
{
	_pType = _x;
	{
		_dataType = getText( _x >> "dataType" );
		if ( _dataType == _pType ) then {
			[ _x, grpNull, _ctx ] call LARs_fnc_spawnCompItems;
		};
	}forEach _itemCfgs;
}forEach _priority;


DEBUG_MSG(DEBUG,"GROUPS");
{
	[ _x, grpNull, _ctx ] call LARs_fnc_spawnCompItems;
}forEach _groupCfgs;


//Items are defered if their id is in a connection or they belong to a defered group
DEBUG_MSG(DEBUG,"DEFERED ITEMS");
{
	_pType = _x;
	{
		_dataType = getText( _x >> "dataType" );
		if ( _dataType == _pType ) then {
			[ _x, grpNull, _ctx ] call LARs_fnc_spawnCompItems;
		};
	}forEach _deferedItems;
}forEach _priority;


//Groups are defered if they have crewLinks or a unit of the group has a random start pos
DEBUG_MSG(DEBUG,"DEFERED GROUPS");
{
	[ _x, grpNull, _ctx ] call LARs_fnc_spawnCompItems;
}forEach _deferedGrps;


//Triggers are defered if they are in connections of type TriggerOwner
DEBUG_MSG(DEBUG,"DEFERED TRIGGERS");
{
	[ _x, true, _ctx ] call LARs_fnc_spawnCompItems;
}forEach _deferedTrgs;


DEBUG_MSG(DEBUG,"CREW LINKS");
private [ "_unit", "_veh" ];
{
	_x params[ "_unitID", "_vehID", "_role", "_turret", "_cargoIndex" ];

	_unit = _ids select _unitID;
	_veh = _ids select _vehID;

	switch ( true ) do {
		case ( _turret isNotEqualTo [] ) : {
			_unit moveInTurret [ _veh, _turret ];
		};
		case ( _cargoIndex > -1 ) : {
			_unit moveInCargo [ _veh, _cargoIndex ];
		};
		default {
			_unit moveInDriver _veh;
		};
	};
}forEach _crewLinks;


DEBUG_MSG(DEBUG,"CONNECTIONS");
if ( isClass( _compCfg >> "connections" ) ) then {
	[_ctx] call LARs_fnc_createLinks;
};


DEBUG_MSG(DEBUG,"INITS");
{
	_x params [ "_obj", "_code" ];
	_obj call compile _code;
}forEach _inits;

_msg = format[ "Composition %1 Done!!", str _compName ];
DEBUG_MSG(DEBUG,_msg);

_ids
