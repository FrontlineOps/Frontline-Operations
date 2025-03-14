 // Town Civilian System
params ["_thisTownCivTrigger"];

// Initialize variables
private _triggerPos = getPos _thisTownCivTrigger;
private _chance = selectRandom [1, 2, 3];
private _repScore = parseNumber (markerText ((allMapMarkers select {markerColor _x == "Color4_FD_F"}) select 0));

// Equipment array
private _equipmentArray = ["C_UavTerminal","ItemRadio","MobilePhone","Rangefinder","acc_pointer_IR","U_BG_leader","ItemCompass","MineDetector","U_I_FullGhillie_lsh","U_BG_Guerilla1_1","C_UavTerminal","ItemRadio","MobilePhone","Rangefinder","acc_pointer_IR","U_BG_leader","ItemCompass","MineDetector","U_I_FullGhillie_lsh","U_BG_Guerilla1_1","MobilePhone","C_UavTerminal","ItemRadio","MobilePhone","Rangefinder","acc_pointer_IR","U_BG_leader","ItemCompass","MineDetector","U_I_FullGhillie_lsh","U_BG_Guerilla1_1","arifle_Mk20_F","arifle_Mk20_GL_F","arifle_Mk20_GL_plain_F","arifle_Mk20_plain_F","arifle_Mk20C_F","arifle_Mk20C_plain_F","arifle_SDAR_F","arifle_TRG20_F","arifle_TRG21_F","arifle_TRG21_GL_F","hgun_ACPC2_F","hgun_PDW2000_F","hgun_Pistol_Signal_F","launch_I_Titan_F","launch_I_Titan_short_F","launch_NLAW_F","launch_RPG32_F","launch_Titan_F","launch_Titan_short_F","LMG_Mk200_F","srifle_DMR_06_camo_F","srifle_DMR_06_olive_F","srifle_EBR_F","srifle_GM6_camo_F","srifle_GM6_F"];

// Cache building positions
private _allBuildings = nearestObjects [_triggerPos, ["HOUSE"], 80];
private _allPositions = [];
{
    _allPositions append (_x buildingPos -1);
    _x removeAllEventHandlers "Killed";
    _x addEventHandler ["Killed", {
        [] execVM "Scripts\ReputationMinus.sqf";
        [] execVM "Scripts\Civ_Relations.sqf";
    }];
} forEach _allBuildings;

// Vehicle spawn function
private _fnc_spawnVehicle = {
    params ["_range"];
    private _roads = _triggerPos nearRoads _range;
    if (count _roads == 0) exitWith {};
    
    private _road = selectRandom _roads;
    private _vehType = selectRandom CivVehArray;
    private _roadDir = if (count roadsConnectedTo _road > 0) then {
        _road getDir ((roadsConnectedTo _road) select 0)
    } else {
        random 360
    };
    
    // Try both sides of the road
    private _sides = [90, -90];
    private _veh = objNull;
    
    {
        private _roadPos = _road getRelPos [6, _x];
        private _safePos = [
            _roadPos,
            0,          // min distance
            8,          // max distance
            (sizeOf _vehType) + 1, // object size + buffer
            0.3,        // max gradient
            0,          // max water depth
            0,          // shore mode
            [],         // blacklist positions
            [_roadPos, _roadPos] // default pos
        ] call BIS_fnc_findSafePos;
        
        // Check if position is not on road and surface is suitable
        if (!isOnRoad _safePos && {!(surfaceIsWater _safePos)}) then {
            _veh = createVehicle [_vehType, [_safePos select 0, _safePos select 1, (_roadPos select 2) + 0.2], [], 0, "CAN_COLLIDE"];
            _veh setDir _roadDir;
            
            // If vehicle is stuck or in bad position, delete and try other side
            if (!alive _veh || {(vectorUp _veh) select 2 < 0.8}) then {
                deleteVehicle _veh;
                _veh = objNull;
            } else {
                breakOut "_fnc_spawnVehicle";
            };
        };
    } forEach _sides;
    
    // If no good position found, try directly on the road as last resort
    if (isNull _veh) then {
        _veh = createVehicle [_vehType, getPos _road, [], 0, "CAN_COLLIDE"];
        _veh setDir _roadDir;
    };
    
    _veh
};

// Spawn vehicles based on chance
if (_chance > 0) then {
    [100] call _fnc_spawnVehicle;
    [100] call _fnc_spawnVehicle;
};

if (_chance > 1) then {
    [100] call _fnc_spawnVehicle;
    [2000] call _fnc_spawnVehicle;
};

if (_chance > 2) then {
    [100] call _fnc_spawnVehicle;
    [2000] call _fnc_spawnVehicle;
};

// Spawn civilian function
private _fnc_spawnCivilian = {
    params ["_enablePatrol", ["_isEngineer", false]];
    if (count _allPositions == 0) exitWith { grpNull };
    
    private _group = [selectRandom _allPositions, civilian, [selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
    private _unit = leader _group;
    
    _unit disableAI "all";
    _unit enableAI "ANIM";
    
    if (_enablePatrol) then {
        _unit enableAI "MOVE";
        _unit enableAI "PATH";
        _unit enableAI "TEAMSWITCH";
        [_group, _triggerPos getPos [random 100, random 350], 90] call BIS_fnc_taskPatrol;
    };
    
    if (_isEngineer) then {
        _unit setUnitTrait ["engineer", true];
    };
    
    _group
};

// Spawn civilians and handle equipment
{
    private _grp = [false] call _fnc_spawnCivilian;
    if (!isNull _grp) then {
        private _unit = leader _grp;
        private _nearBuilding = nearestObject [getPos _unit, "HOUSE"];
        if (!isNull _nearBuilding) then {
            private _buildingPos = selectRandom (_nearBuilding buildingPos -1);
            if (count _buildingPos > 0) then {
                private _holder = createVehicle ["groundweaponholder", _buildingPos, [], 0, "CAN_COLLIDE"];
                _holder addItemCargo [selectRandom _equipmentArray, 1];
            };
        };
    };
} forEach [1,2];

// Additional civilians based on reputation
if (markerColor ([allMapMarkers, _thisTownCivTrigger] call BIS_fnc_nearestPosition) == "colorOPFOR" || _repScore < 7) then {
    [true, true] call _fnc_spawnCivilian;
};

// Spawn patrolling civilians
{
    [true] call _fnc_spawnCivilian;
} forEach [1,2,3,4,5];

// Handle military installations and IEDs
private _nearestInstallation = [
    allMapMarkers select {
        private _type = markerType _x;
        _type in ["n_installation", "o_installation", "o_antiair", "o_service", 
                 "o_armor", "loc_Power", "o_recon", "o_support", "n_support", "loc_Ruin"]
    },
    _thisTownCivTrigger
] call BIS_fnc_nearestPosition;

if ((_triggerPos distance2D getMarkerPos _nearestInstallation) < 1500) then {
    private _ieds = ["IEDUrbanSmall_F", "IEDUrbanBig_F", "IEDLandSmall_F", "IEDLandBig_F"];
    private _clutters = ["Land_Garbage_square3_F", "Land_Garbage_line_F"];
    
    // Spawn guerrilla forces based on reputation
    if (_repScore > 10 || _repScore < 7) then {
        {
            private _group = [selectRandom _allPositions, independent, [selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
            [_group, _triggerPos getPos [random 100, random 350], 90] call BIS_fnc_taskPatrol;
        } forEach [1,2,3];
    };
    
    if (_repScore > 12 || _repScore < 5) then {
        {
            private _group = [selectRandom _allPositions, independent, [selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
            [_group, _triggerPos getPos [random 100, random 350], 90] call BIS_fnc_taskPatrol;
        } forEach [1,2,3];
    };
    
    // IED placement function
    private _fnc_placeIED = {
        private _roads = _triggerPos nearRoads 100;
        if (count _roads == 0) exitWith {};
        
        private _road = selectRandom _roads;
        private _pos = _road getRelPos [8, selectRandom [0, 180]];
        
        private _clutter = createVehicle [selectRandom _clutters, _pos, [], random 2, "CAN_COLLIDE"];
        _clutter setVectorUp [0,0,1];
        
        private _ied = createMine [selectRandom _ieds, _pos, [], 0];
        
        // IED trigger
        private _triggerIED = createTrigger ["EmptyDetector", _pos];
        _triggerIED setTriggerArea [10, 10, 0, false, 4];
        _triggerIED setTriggerInterval 1;
        _triggerIED setTriggerActivation ["WEST", "PRESENT", false];
        _triggerIED setTriggerStatements [
            "this && stance player != 'PRONE'",
            "[(getPos thisTrigger)] execVM 'Scripts\IEDEXP.sqf';
            private _triggers = allMissionObjects 'EmptyDetector' select {triggerInterval _x == 2 && getPos _x distance thisTrigger < 7};
            if (count _triggers > 0) then { deleteVehicle (_triggers select 0) };
            deleteVehicle thisTrigger;",
            ""
        ];
        
        // Disarm trigger
        private _triggerDisarm = createTrigger ["EmptyDetector", _pos];
        _triggerDisarm setTriggerArea [5, 5, 0, false, 5];
        _triggerDisarm setTriggerInterval 2;
        _triggerDisarm setTriggerActivation ["ANYPLAYER", "PRESENT", false];
        _triggerDisarm setTriggerStatements [
            "count (allMines select {position _x inArea thisTrigger}) == 0",
            "
            private _markers = allMapMarkers select { markerType _x == 'hd_unknown' && markerPos _x inArea thisTrigger};
            { deleteMarker _x } forEach _markers;
            [70, 'IED'] call FLO_fnc_notification;
            [70] call FLO_fnc_addReward;
            [] execVM 'Scripts\ReputationPlus.sqf';
            execVM 'Scripts\Civ_Relations.sqf';
            private _triggers = allMissionObjects 'EmptyDetector' select {triggerInterval _x == 1 && getPos _x distance thisTrigger < 7};
            if (count _triggers > 0) then { deleteVehicle (_triggers select 0) };
            deleteVehicle thisTrigger;",
            ""
        ];
    };
    
    // Place IEDs based on reputation
    if (_repScore < 7) then {
        { call _fnc_placeIED } forEach [1,2,3];
    };
    
    if (_repScore < 5) then {
        { call _fnc_placeIED } forEach [1,2,3];
    };
};

// Handle building lights
private _buildings = nearestObjects [_triggerPos, ["HOUSE"], 20] select { count (_x buildingPos -1) > 4 };
{
    createVehicle ["Land_Camping_Light_F", [(getPos _x select 0), (getPos _x select 1), (getPos _x select 2) + 1], [], 0, "NONE"];
} forEach _buildings;

// Day/Night cycle for civilians
[_triggerPos] spawn {
    params ["_pos"];
    while {true} do {
        private _civilians = allUnits select { 
            side _x == civilian && 
            _x checkAIFeature "PATH" && 
            _x distance2D _pos < 200
        };
        
        if (dayTime < 19 && dayTime > 7) then {
            { _x hideObjectGlobal false; _x enableSimulationGlobal true } forEach _civilians;
        } else {
            { _x hideObjectGlobal true; _x enableSimulationGlobal false } forEach _civilians;
        };
        sleep 60;
    };
};

sleep 5;

execVM "Scripts\Civ_Relations.sqf";