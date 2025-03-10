/*
    Function: FLO_fnc_initializeFOB
    
    Description:
    Initializes a FOB with all necessary features - creation factory, arsenal, 
    action menu, triggers, event handlers, and siege monitoring.
    
    Parameters:
    _this select 0: OBJECT - The FOB building to initialize
    _this select 1: BOOL - (Optional) Whether to preserve existing marker (default: false)
    
    Returns:
    Nothing
*/

params [
    ["_fobBuilding", objNull, [objNull]],
    ["_preserveMarker", false, [false]]
];

if (isNull _fobBuilding) exitWith {
    ["FOB", 1, "Error: Null object passed to FOB initialization"] call FLO_fnc_log;
};

// Check if FOB was already initialized
if (_fobBuilding getVariable ["FLO_FOB_Initialized", false]) exitWith {
    ["FOB", 3, format["FOB at %1 already initialized - skipping", getPos _fobBuilding]] call FLO_fnc_log;
};

// Mark as initialized to prevent duplicate initialization
_fobBuilding setVariable ["FLO_FOB_Initialized", true, true];

// Create marker and set variable if not preserving existing marker
private _markerName = "";
if (_preserveMarker && {_fobBuilding getVariable ["FLO_FOB_MarkersRestored", false]}) then {
    // Use the existing marker name that was restored from save
    _markerName = _fobBuilding getVariable ["fobMarkerName", ""];
    ["FOB", 3, format["Using restored FOB marker %1", _markerName]] call FLO_fnc_log;
} else {
    // Create a new marker
    private _relpos = _fobBuilding getRelPos [12, 0];
    _markerName = "respawn_west" + (str (getPos _fobBuilding));
    _fobBuilding setVariable ["fobMarkerName", _markerName, true];

    // Check if marker already exists (from mission load)
    private _markerExists = false;
    {
        if (_x isEqualTo _markerName) exitWith {
            _markerExists = true;
            ["FOB", 3, format["Using existing FOB marker %1", _markerName]] call FLO_fnc_log;
        };
    } forEach allMapMarkers;

    // Only create marker if it doesn't exist
    if (!_markerExists) then {
        private _mrkr = createMarker [_markerName, _relpos];  
        _mrkr setMarkerType "b_installation";
        _mrkr setMarkerColor "ColorYellow";
        _mrkr setMarkerText "FOB";
        _mrkr setMarkerSize [2, 2];
        ["FOB", 3, format["Created new FOB marker %1", _markerName]] call FLO_fnc_log;
    };
};

// Initialize creation factory
if (!isNil "_fobBuilding" && {!isNull _fobBuilding}) then {
    [[_fobBuilding, -1, west, "LIGHT"], "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"] remoteExec ["execVM", 0, true];
} else {
    ["FOB", 2, "Failed to initialize FOB creation factory - _fobBuilding is nil or null"] call FLO_fnc_log;
};

// Add Arsenal action
[ _fobBuilding,
"<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
"Screens\FOBA\mg_ca.paa",
"Screens\FOBA\mg_ca.paa",
    "_this distance _target < 10",            
    "_caller distance _target < 10",    
{},
{},
{
    if (isClass (configfile >> "ace_arsenal_loadoutsDisplay") isEqualTo true ) then {
        [player, player, true] call ace_arsenal_fnc_openBox;
    } else {
        ["Open", true] spawn BIS_fnc_arsenal;
    };
},
{},
[],
1,
9999999,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

// Add Pack FOB action
[ _fobBuilding,
"<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Pack FOB",
"Screens\FOBA\b_hq.paa",
"Screens\FOBA\b_hq.paa",
"player isEqualTo TheCommander",       
"_caller distance _target < 40",  
{},
{},
{execVM 'Scripts\PObjectives\FOBPACK.sqf';},
{},
[],
5,
2,
false,
false
] remoteExec ["BIS_fnc_holdActionAdd",0,true];   

// Add Request Menu action
[_fobBuilding,[
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>REQUEST MENU",
    "Scripts\RequestMenu\Dialog_Request.sqf",
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
_CIVTRG = createTrigger ["EmptyDetector", getPos _fobBuilding];  
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

_CIVTRG attachTo [_fobBuilding, [0, 0, 0]]; 

// Add Resource Trigger
_TFOBA = createTrigger ["EmptyDetector", getPos _fobBuilding];  
_TFOBA setTriggerArea [5, 5, 0, false, 7];  
_TFOBA setTriggerTimeout [3, 3, 3, true];
_TFOBA setTriggerActivation ["NONE", "PRESENT", true];  
_TFOBA setTriggerStatements [  
"count (nearestobjects [thisTrigger,['CargoNet_01_box_F'],4]) > 0 ",  
"  
_RES = nearestobjects [thisTrigger,['CargoNet_01_box_F'],10] select 0 ;    
deleteVehicle _RES ; 
    [100, 'RESOURCE'] call FLO_fnc_notification ;
[100, thisTrigger] execVM 'Scripts\Reward_Supplies.sqf';
", ""]; 

_TFOBA attachTo [_fobBuilding, [0, 0, 0]]; 

// Add Killed Event Handler
_fobBuilding addEventHandler ["Killed", {
    [playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the FOB,...';
    _FOBC = nearestObjects [ (_this select 0), ['B_Slingload_01_Cargo_F'], 1000] select 0;
    _FOBB = nearestObjects [ (_this select 0), [F_HQ_01], 1000] select 0;
    _FOBT = nearestObjects [(_this select 0), [F_HQ_C_01], 1000]  select 0;
    deleteVehicle _FOBC;
    _FOBB setdamage 1;
    deleteVehicle _FOBT;
    
    private _markerName = _this select 0 getVariable "fobMarkerName";
    deleteMarker _markerName;
    
    [] execVM 'Scripts\Failed.sqf';

    _alltriggers = allMissionObjects "EmptyDetector";
    _triggers = _alltriggers select {position _x distance (_this select 0) < 20};
    {deleteVehicle _x;} forEach _triggers;
}]; 

// Start holdout monitoring for FOB
[_fobBuilding] spawn {
    params ["_fob"];
    private _holdoutTime = 0;
    private _maxHoldTime = 900; // 15 minutes for FOB
    private _checkInterval = 1;
    private _areaRadius = 200;
    private _statusMarker = nil;
    
    while {alive _fob} do {
        private _bluforCount = {alive _x && side _x isEqualTo west && (_x distance _fob) < _areaRadius} count allUnits;
        private _opforCount = {alive _x && side _x isEqualTo east && (_x distance _fob) < _areaRadius} count allUnits;

        if (_opforCount > _bluforCount && _opforCount > 0) then {
            if (isNil "_statusMarker") then {
                _statusMarker = createMarker ["FOB_Status", getPos _fob];
                _statusMarker setMarkerType "mil_objective";
                _statusMarker setMarkerColor "ColorRed";
                _statusMarker setMarkerSize [1.5,1.5];
            };
            
            _holdoutTime = _holdoutTime + _checkInterval;
            private _timeLeft = _maxHoldTime - _holdoutTime;
            private _minutes = floor(_timeLeft/60);
            private _seconds = _timeLeft % 60;
            _statusMarker setMarkerText format["FOB UNDER SIEGE: %1:%2", _minutes, [_seconds, 2] call CBA_fnc_formatNumber];
            
            if (_timeLeft % 60 isEqualTo 0) then {
                [format["FOB under siege! %1 minutes remaining", ceil(_timeLeft/60)]] remoteExec ["hint", -2];
            };
            
            if (_holdoutTime >= _maxHoldTime) exitWith {
                _statusMarker setMarkerText "FOB LOST!";
                _statusMarker setMarkerColor "ColorBlack";
                deleteMarker _statusMarker;
                
                "FOB has fallen to enemy forces!" remoteExec ["hint", -2];
                
                private _FOBC = nearestObjects [_fob, ['B_Slingload_01_Cargo_F'], 1000] param [0, objNull];
                private _FOBT = nearestObjects [_fob, [F_HQ_C_01], 1000] param [0, objNull];
                
                if (!isNull _FOBC) then { deleteVehicle _FOBC };
                if (!isNull _fob) then { _fob setDamage 1 };
                if (!isNull _FOBT) then { deleteVehicle _FOBT };
                
                private _markerName = _fob getVariable "fobMarkerName";
                deleteMarker _markerName;
                
                private _allTriggers = allMissionObjects "EmptyDetector";
                private _triggers = _allTriggers select { position _x distance _fob < 500 };
                { deleteVehicle _x } forEach _triggers;
                
                // Call failure script
                [] execVM 'Scripts\Failed.sqf';
            };
        } else {
            if (!isNil "_statusMarker") then {
                deleteMarker _statusMarker;
                _statusMarker = nil;
                if (_holdoutTime > 0) then {
                    "FOB defense successful! Timer reset." remoteExec ["hint", -2];
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

["FOB", 3, format["FOB initialized at position %1", getPos _fobBuilding]] call FLO_fnc_log; 