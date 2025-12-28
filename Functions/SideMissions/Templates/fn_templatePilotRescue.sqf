/*
 * Function: FLO_fnc_templatePilotRescue
 * Author: Frontline Operations Development Group
 * Description:
 *   Template definition for the Pilot Rescue side mission.
 *   Rescues a downed pilot from an enemy-held location.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _template = createHashMapFromArray [
    ["name", "Rescue Downed Pilot"],
    ["description", "Intel indicates a friendly aircraft crash site. Track down and rescue the pilot, then destroy the wreck."],
    ["icon", "mil_pickup"],
    ["color", "colorBLUFOR"],
    ["cooldown", 900],
    ["timeout", 3600],
    ["maxActive", 1],
    ["reward", 75],
    ["isConvoy", false],
    
    // Setup function - finds position and validates spawn
    ["fnc_setup", {
        params ["_typeName"];
        
        private _position = [0,0,0];
        private _canSpawn = false;
        
        // Find a suitable house near an OPFOR-controlled objective
        private _objId = [4000, getPos player, east] call FLO_fnc_getObjectiveNearPlayer;
        if (_objId != "") then {
            _position = [_objId] call FLO_fnc_getRandomObjectivePos;
        } else {
            _position = player getPos [1000 + random 2000, random 360];
        };
        
        private _house = [_position] call FLO_fnc_findMissionHouse;
        if (!isNull _house) then {
            _position = getPos _house;
            _canSpawn = true;
        };
        
        [_canSpawn, _position]
    }],
    
    // Spawn function - creates mission entities
    ["fnc_spawn", {
        params ["_missionId"];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        // Find house at position
        private _house = ([_position] call FLO_fnc_findMissionHouse);
        if (isNull _house) exitWith {};
        
        private _buildingPos = _house buildingPos -1;
        if (count _buildingPos == 0) then { _buildingPos = [getPos _house]; };
        
        // Spawn crash site composition
        ["Intel_CS_01", selectRandom _buildingPos, [0,0,0], getDirVisual _house, false, false, true] call LARs_fnc_spawnComp;
        
        // Spawn pilot (captive)
        private _pilotGroup = [selectRandom _buildingPos, West, ["B_Pilot_F"]] call BIS_fnc_spawnGroup;
        private _pilot = (units _pilotGroup) select 0;
        _pilot setCaptive true;
        _pilot disableAI "PATH";
        _pilot playMoveNow "Acts_AidlPsitMstpSsurWnonDnon01";
        ["addEntity", [_missionId, _pilot]] call FLO_fnc_sideMissionEntityTracker;
        
        // Store pilot reference for success check
        private _data = _instance get "data";
        _data set ["pilot", _pilot];
        _data set ["house", _house];
        
        // Spawn garrison guards
        for "_i" from 1 to 4 do {
            private _grp = [selectRandom _buildingPos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
            if (_i <= 2) then { ((units _grp) select 0) disableAI "PATH"; };
            _grp deleteGroupWhenEmpty true;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Spawn patrol
        private _patrolGrp = [getPos _house, East, [
            selectRandom East_Units, selectRandom East_Units,
            selectRandom East_Units, selectRandom East_Units
        ]] call BIS_fnc_spawnGroup;
        [_patrolGrp, getPos _house, 300] call BIS_fnc_taskPatrol;
        _patrolGrp deleteGroupWhenEmpty true;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Additional enemies based on difficulty
        if (_aggrScore > 5) then {
            private _grp = [_house getPos [100, random 360], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
            [_grp, getPos _house, 200] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        if (_aggrScore > 10) then {
            private _grp = [_house getPos [200, random 360], East, [selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
            [_grp, getPos _house, 500] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Create BIS task
        [_missionId] call FLO_fnc_sideMissionTaskCreate;
    }],
    
    // Success condition - pilot rescued (in friendly vehicle or at base)
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _pilot = _data getOrDefault ["pilot", objNull];
        
        if (isNull _pilot || !alive _pilot) exitWith { false };
        
        // Check if pilot is in a friendly vehicle
        private _veh = vehicle _pilot;
        if (_veh != _pilot && {side _veh == West}) exitWith { true };
        
        // Check if pilot is near any player and not captive
        if (!captive _pilot) then {
            private _nearPlayer = (allPlayers findIf { _x distance _pilot < 10 }) >= 0;
            if (_nearPlayer) exitWith { true };
        };
        
        false
    }],
    
    // Fail condition - pilot killed
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _pilot = _data getOrDefault ["pilot", objNull];
        
        !isNull _pilot && {!alive _pilot}
    }],
    
    // Cleanup function
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
        // Entity cleanup handled by EntityTracker
    }]
];

_template

