/*
 * Function: FLO_fnc_templatePOWRescue
 * Author: Frontline Operations Development Group
 * Description:
 *   Template for the POW Rescue side mission.
 *   Rescue prisoners of war from an enemy camp.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _template = createHashMapFromArray [
    ["name", "Rescue POWs"],
    ["description", "Intel indicates a nearby POW camp. Rescue our captured forces and return them safely."],
    ["icon", "mil_pickup"],
    ["color", "colorBLUFOR"],
    ["cooldown", 1200],
    ["timeout", 3600],
    ["maxActive", 1],
    ["reward", 100],
    ["isConvoy", false],
    
    ["fnc_setup", {
        params ["_typeName"];
        
        private _position = [0,0,0];
        private _canSpawn = false;
        
        // Find OPFOR-controlled objective only
        private _objId = [4000, getPos player, east] call FLO_fnc_getObjectiveNearPlayer;
        if (_objId != "") then {
            _position = [_objId] call FLO_fnc_getRandomObjectivePos;
            _canSpawn = true;
        } else {
            private _house = [getPos player] call FLO_fnc_findMissionHouse;
            if (!isNull _house) then {
                _position = getPos _house;
                _canSpawn = true;
            };
        };
        
        [_canSpawn, _position]
    }],
    
    ["fnc_spawn", {
        params ["_missionId"];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        private _data = _instance get "data";
        
        // Find barracks-type building
        private _barracks = nearestObjects [_position, [
            "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
            "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "HOUSE"
        ], 400] select 0;
        
        if (isNull _barracks) then { _barracks = ([_position] call FLO_fnc_findMissionHouse); };
        if (isNull _barracks) exitWith {};
        
        private _buildingPos = _barracks buildingPos -1;
        if (count _buildingPos == 0) then { _buildingPos = [getPos _barracks]; };
        
        _data set ["barracks", _barracks];
        
        // Spawn POWs
        private _pows = [];
        private _powCount = 2 + floor random 3;
        for "_i" from 1 to _powCount do {
            private _unitType = selectRandom ["B_Soldier_F", "B_Soldier_lite_F", "B_medic_F"];
            private _grp = [selectRandom _buildingPos, West, [_unitType]] call BIS_fnc_spawnGroup;
            private _unit = (units _grp) select 0;
            _unit setCaptive true;
            _unit disableAI "PATH";
            removeAllWeapons _unit;
            _pows pushBack _unit;
            ["addEntity", [_missionId, _unit]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        _data set ["pows", _pows];
        _data set ["initialCount", count _pows];
        
        // Spawn intel composition
        ["Intel_01", selectRandom _buildingPos, [0,0,0], 0, false, false, true] call LARs_fnc_spawnComp;
        
        // Spawn officer
        private _officerGrp = [selectRandom _buildingPos, East, [selectRandom East_Units_Officers]] call BIS_fnc_spawnGroup;
        private _officer = (units _officerGrp) select 0;
        _officer disableAI "PATH";
        ["addGroup", [_missionId, _officerGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Garrison guards
        private _garrisonCount = 2 + (if (_aggrScore > 5) then {2} else {0}) + (if (_aggrScore > 10) then {2} else {0});
        for "_i" from 1 to _garrisonCount do {
            private _grp = [selectRandom _buildingPos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
            if (_i % 2 == 0) then { ((units _grp) select 0) disableAI "PATH"; };
            _grp deleteGroupWhenEmpty true;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Patrols
        private _patrolGrp = [_position getPos [50, random 360], East, [
            selectRandom East_Units, selectRandom East_Units, selectRandom East_Units
        ]] call BIS_fnc_spawnGroup;
        [_patrolGrp, _position, 100] call BIS_fnc_taskPatrol;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        if (_aggrScore > 5) then {
            private _grp = [_position getPos [100, random 360], East, [
                selectRandom East_Units, selectRandom East_Units, selectRandom East_Units
            ]] call BIS_fnc_spawnGroup;
            [_grp, _position, 200] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        if (_aggrScore > 10) then {
            private _grp = [_position getPos [150, random 360], East, [
                selectRandom East_Units, selectRandom East_Units, selectRandom East_Units
            ]] call BIS_fnc_spawnGroup;
            [_grp, _position, 200] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        [_missionId] call FLO_fnc_sideMissionTaskCreate;
    }],
    
    // Success - at least half POWs rescued
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _pows = _data getOrDefault ["pows", []];
        private _initialCount = _data getOrDefault ["initialCount", 1];
        
        private _rescued = { alive _x && {!captive _x} && {
            (allPlayers findIf { _forEachIndex distance _x < 50 }) >= 0 || 
            {vehicle _x != _x && {side vehicle _x == West}}
        }} count _pows;
        
        _rescued >= (_initialCount / 2)
    }],
    
    // Fail - all POWs killed
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _pows = (_instance get "data") getOrDefault ["pows", []];
        count _pows > 0 && {({ alive _x } count _pows) == 0}
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
    }]
];

_template

