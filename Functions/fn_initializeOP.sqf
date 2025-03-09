/*
    Function: FLO_fnc_initializeOP
    
    Description:
    Initializes an Observation Post with all necessary features - creation factory, arsenal, 
    action menu, triggers, event handlers, and siege monitoring.
    
    Parameters:
    _this select 0: OBJECT - The OP building to initialize
    _this select 1: BOOL - (Optional) Whether to preserve existing marker (default: false)
    
    Returns:
    Nothing
*/

if (!isServer) exitWith {};

params [
    ["_opBuilding", objNull, [objNull]],
    ["_preserveMarker", false, [false]]
];

if (isNull _opBuilding) exitWith {
    ["OP", 1, "Error: Null object passed to OP initialization"] call FLO_fnc_log;
};

// Check if OP was already initialized
if (_opBuilding getVariable ["FLO_OP_Initialized", false]) exitWith {
    ["OP", 3, format["OP at %1 already initialized - skipping", getPos _opBuilding]] call FLO_fnc_log;
};

// Mark as initialized to prevent duplicate initialization
_opBuilding setVariable ["FLO_OP_Initialized", true, true];

// Create marker and set variable if not preserving existing marker
private _markerName = "";
if (_preserveMarker && {_opBuilding getVariable ["FLO_OP_MarkersRestored", false]}) then {
    // Use the existing marker name that was restored from save
    _markerName = _opBuilding getVariable ["opMarkerName", ""];
    ["OP", 3, format["Using restored OP marker %1", _markerName]] call FLO_fnc_log;
} else {
    // Create a new marker
    private _relpos = _opBuilding getRelPos [12, 0];
    _markerName = "respawn_west" + (str (getPos _opBuilding));
    _opBuilding setVariable ["opMarkerName", _markerName, true];

    // Check if marker already exists (from mission load)
    private _markerExists = false;
    {
        if (_x isEqualTo _markerName) exitWith {
            _markerExists = true;
            ["OP", 3, format["Using existing OP marker %1", _markerName]] call FLO_fnc_log;
        };
    } forEach allMapMarkers;

    // Only create marker if it doesn't exist
    if (!_markerExists) then {
        private _mrkr = createMarker [_markerName, _relpos];  
        _mrkr setMarkerType "b_installation";
        _mrkr setMarkerColor "ColorYellow";
        _mrkr setMarkerText "OP";
        _mrkr setMarkerSize [1.5, 1.5];
        ["OP", 3, format["Created new OP marker %1", _markerName]] call FLO_fnc_log;
    };
};

// Initialize creation factory
if (!isNil "_opBuilding" && {!isNull _opBuilding}) then {
    [[_opBuilding, -1, west, "LIGHT"], "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"] remoteExec ["execVM", 0, true];
} else {
    ["OP", 2, "Failed to initialize OP creation factory - _opBuilding is nil or null"] call FLO_fnc_log;
};

// Add Arsenal action
[ _opBuilding,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
    "_this distance _target < 10",            
    "_caller distance _target < 10",    
{},
{},
{
    if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") isEqualTo true) then {
        [player, player, true] call ace_arsenal_fnc_openBox;
    } else {
        ["Open", true] spawn BIS_fnc_arsenal;
    };
},
{},
[],
1,
1,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

// Add Pack OP action
[_opBuilding,
"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Pack OP",
"Screens\FOBA\b_hq.paa",
"Screens\FOBA\b_hq.paa",
"true",       
"_caller distance _target < 40",  
{},
{},
{execVM 'Scripts\OPPACK.sqf';},
{},
[],
5,
2,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

// Add Request Menu action
[_opBuilding,[
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
    "Scripts\RequestMenu\Dialog_Request_OP.sqf",
    nil,
    99999,
    true,
    true,
    "",
    "", // _target, _this, _originalTarget
    40,
    false,
    "",
    ""
]] remoteExec ["addAction",0,true];

// Add Civilian Handling Trigger
_CIVTRG = createTrigger ["EmptyDetector", getPos _opBuilding];  
_CIVTRG setTriggerArea [5, 5, 0, false, 7];  
_CIVTRG setTriggerTimeout [3, 3, 3, true];
_CIVTRG setTriggerActivation ["NONE", "PRESENT", true];  
_CIVTRG setTriggerStatements [  
"{(alive _x) && (side _x isEqualTo civilian)} count (thisTrigger nearEntities [['Man'], 5]) > 0",  
"
_CIVIL = (nearestObjects [thisTrigger ,['Man'], 7] select {(alive _x) && ((side _x) isEqualTo civilian)}) select 0 ;
  
if (_CIVIL getUnitTrait 'engineer' isEqualTo true) then {
    [50, 'INSURGENT'] call FLO_fnc_notification ;
    [50] call FLO_fnc_addReward;
    deleteVehicle _CIVIL ; 
    [] execVM 'Scripts\INTL_Civ.sqf';    
    [] execVM 'Scripts\ReputationPlus.sqf';
} else {
    [0, 'CIVILIAN'] call FLO_fnc_notification ;
    deleteVehicle _CIVIL ; 
    [] execVM 'Scripts\ReputationMinus.sqf';
};
", ""]; 

_CIVTRG attachTo [_opBuilding, [0, 0, 0]]; 

// Add Resource Trigger
_TFOBA = createTrigger ["EmptyDetector", getPos _opBuilding];  
_TFOBA setTriggerArea [3, 3, 0, false, 7];  
_TFOBA setTriggerTimeout [3, 3, 3, true];
_TFOBA setTriggerActivation ["NONE", "PRESENT", true];  
_TFOBA setTriggerStatements [  
"count (nearestobjects [thisTrigger,['CargoNet_01_box_F'],3]) > 0 ",  
"  
_RES = nearestobjects [thisTrigger,['CargoNet_01_box_F'],10] select 0 ;    
deleteVehicle _RES ; 
    [100, 'RESOURCE'] call FLO_fnc_notification ;
[100, thisTrigger] execVM 'Scripts\Reward_Supplies.sqf';
", ""]; 

_TFOBA attachTo [_opBuilding, [0, 0, 0]]; 

// Add Killed Event Handler
_opBuilding addEventHandler ["Killed", {
    [playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the OP,...';
    _FOBC = nearestObjects [ (_this select 0), ['B_Slingload_01_Cargo_F'], 1000] select 0;
    _FOBB = nearestObjects [ (_this select 0), [F_OP_01], 1000] select 0;
    _FOBT = nearestObjects [(_this select 0), [F_OP_C_01], 1000] select 0;
    deleteVehicle _FOBC;
    _FOBB setdamage 1;
    deleteVehicle _FOBT;
    
    private _markerName = _this select 0 getVariable "opMarkerName";
    deleteMarker _markerName;
    
    _alltriggers = allMissionObjects "EmptyDetector";
    _triggers = _alltriggers select {position _x distance (_this select 0) < 20};
    {deleteVehicle _x;} forEach _triggers;
}]; 

// Modified holdout monitoring for OP
[_opBuilding] spawn {
    params ["_op"];
    private _holdoutTime = 0;
    private _maxHoldTime = 600; // 10 minutes for OP
    private _checkInterval = 1;
    private _areaRadius = 100;
    private _statusMarker = nil;
    
    while {alive _op} do {
        private _bluforCount = {alive _x && side _x isEqualTo west && (_x distance _op) < _areaRadius} count allUnits;
        private _opforCount = {alive _x && side _x isEqualTo east && (_x distance _op) < _areaRadius} count allUnits;

        if (_opforCount > _bluforCount && _opforCount > 0) then {
            if (isNil "_statusMarker") then {
                _statusMarker = createMarker ["OP_Status", getPos _op];
                _statusMarker setMarkerType "mil_objective";
                _statusMarker setMarkerColor "ColorRed";
                _statusMarker setMarkerSize [1.2,1.2];
            };
            
            _holdoutTime = _holdoutTime + _checkInterval;
            private _timeLeft = _maxHoldTime - _holdoutTime;
            private _minutes = floor(_timeLeft/60);
            private _seconds = _timeLeft % 60;
            _statusMarker setMarkerText format["OP UNDER SIEGE: %1:%2", _minutes, [_seconds, 2] call CBA_fnc_formatNumber];
            
            if (_timeLeft % 60 isEqualTo 0) then {
                [format["OP under siege! %1 minutes remaining", ceil(_timeLeft/60)]] remoteExec ["hint", -2];
            };
            
            if (_holdoutTime >= _maxHoldTime) exitWith {
                _statusMarker setMarkerText "OP LOST!";
                _statusMarker setMarkerColor "ColorBlack";
                deleteMarker _statusMarker;
                
                "OP has fallen to enemy forces!" remoteExec ["hint", -2];
                
                // Execute OP destruction sequence
                private _OPC = nearestObjects [_op, ['B_Slingload_01_Cargo_F'], 1000] param [0, objNull];
                private _OPT = nearestObjects [_op, [F_OP_C_01], 1000] param [0, objNull];
                
                if (!isNull _OPC) then { deleteVehicle _OPC };
                if (!isNull _op) then { _op setDamage 1 };
                if (!isNull _OPT) then { deleteVehicle _OPT };
                
                // Delete OP marker
                private _markerName = _op getVariable "opMarkerName";
                deleteMarker _markerName;
                
                // Cleanup triggers
                private _allTriggers = allMissionObjects "EmptyDetector";
                private _triggers = _allTriggers select { position _x distance _op < 300 };
                { deleteVehicle _x } forEach _triggers;
            };
        } else {
            if (!isNil "_statusMarker") then {
                deleteMarker _statusMarker;
                _statusMarker = nil;
                if (_holdoutTime > 0) then {
                    "OP defense successful! Timer reset." remoteExec ["hint", -2];
                };
            };
            _holdoutTime = 0;
        };
        
        sleep _checkInterval;
    };
    
    if (!isNil "_statusMarker") then {
        deleteMarker _statusMarker;
    };
};

// Final notification
[playerSide, "HQ"] commandChat "OP Deployed";

["OP", 3, format["OP initialized at position %1", getPos _opBuilding]] call FLO_fnc_log; 