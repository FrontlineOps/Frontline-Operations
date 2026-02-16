/*
 * Function: FLO_fnc_templatePatrolSweep
 * Author: Frontline Operations Development Group
 * Description:
 *   Template for the Counter-Insurgency Patrol Sweep mission.
 *   Eliminate insurgent activity and destroy their supply stash.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
if !(_activeSide in [east, west]) then { _activeSide = west };
private _enemyColor = if (_activeSide isEqualTo east) then { "colorBLUFOR" } else { "colorOPFOR" };

private _template = createHashMapFromArray [
    ["name", "Counter Insurgency Sweep"],
    ["description", "Enemy patrols and insurgent activity detected nearby. Eliminate threats and destroy their supply stash."],
    ["icon", "mil_objective"],
    ["color", _enemyColor],
    ["cooldown", 600],
    ["timeout", 2700],
    ["maxActive", 2],
    ["reward", 30],
    ["isConvoy", false],
    
    ["fnc_setup", {
        params ["_typeName"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        
        private _position = [0,0,0];
        private _canSpawn = false;
        
        // Find enemy objective only
        private _objId = [1500, getPos player, _enemySide] call FLO_fnc_getObjectiveNearPlayer;
        if (_objId == "") exitWith {
            [false, [0,0,0]]
        };

        private _searchPos = [_objId] call FLO_fnc_getRandomObjectivePos;
        
        private _house = [_searchPos] call FLO_fnc_findMissionHouse;
        if (!isNull _house) then {
            _position = getPos _house;
            _canSpawn = true;
        };
        
        [_canSpawn, _position]
    }],
    
    ["fnc_spawn", {
        params ["_missionId"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        private _enemyKey = if (_enemySide isEqualTo east) then { "EAST" } else { "WEST" };
        private _enemyCatalog = missionNamespace getVariable ["FLO_FactionCatalog", createHashMap] getOrDefault [_enemyKey, createHashMap];
        private _enemyOfficers = _enemyCatalog getOrDefault ["officers", if (!isNil "East_Units_Officers") then { East_Units_Officers } else { _enemyCatalog getOrDefault ["units", ["O_officer_F"]] }];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        private _house = nearestBuilding _position;
        if (isNull _house) exitWith {};
        
        private _buildingPos = _house buildingPos -1;
        if ((count _buildingPos) == 0) then { _buildingPos = [getPos _house]; };
        
        // Create stash
        private _stashPos = selectRandom _buildingPos;
        private _stash = createVehicle ["Box_FIA_Ammo_F", _stashPos, [], 0, "NONE"];
        _stash setPos _stashPos;
        
        private _data = _instance get "data";
        _data set ["stash", _stash];
        _data set ["house", _house];
        ["addEntity", [_missionId, _stash]] call FLO_fnc_sideMissionEntityTracker;
        
        // Spawn officer with intel
        private _officerGrp = [selectRandom _buildingPos, _enemySide, [selectRandom _enemyOfficers]] call BIS_fnc_spawnGroup;
        private _officer = (units _officerGrp) select 0;
        _officer disableAI "PATH";
        _data set ["officer", _officer];
        ["addGroup", [_missionId, _officerGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Spawn insurgents (using civilian clothing)
        private _fnc_spawnInsurgent = {
            params ["_pos", "_disablePath"];
            private _grp = [_pos, _enemySide, [selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
            { _x setUnitLoadout (selectRandom GuerMenArray); removeHeadgear _x; } forEach units _grp;
            if (_disablePath) then { ((units _grp) select 0) disableAI "PATH"; };
            _grp deleteGroupWhenEmpty true;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Garrison
        for "_i" from 1 to 3 do {
            [selectRandom _buildingPos, true] call _fnc_spawnInsurgent;
        };
        
        if (_aggrScore > 5) then {
            private _nearBuildings = (nearestObjects [_position, ["HOUSE"], 200]) select { count (_x buildingPos -1) > 0 };
            private _extraBld = selectRandom _nearBuildings;
            for "_i" from 1 to 3 do {
                [selectRandom (_extraBld buildingPos -1), true] call _fnc_spawnInsurgent;
            };
        };
        
        if (_aggrScore > 10) then {
            private _nearBuildings = (nearestObjects [_position, ["HOUSE"], 200]) select { count (_x buildingPos -1) > 0 };
            private _extraBld = selectRandom _nearBuildings;
            for "_i" from 1 to 3 do {
                [selectRandom (_extraBld buildingPos -1), true] call _fnc_spawnInsurgent;
            };
        };
        
        // Patrol
        private _patrolPos = _position getPos [30, random 360];
        private _patrolGrp = [_patrolPos, _enemySide, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
        { _x setUnitLoadout (selectRandom GuerMenArray); removeHeadgear _x; } forEach units _patrolGrp;
        _patrolGrp deleteGroupWhenEmpty true;
        [_patrolGrp, _position, 50, 4, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;

        if (_aggrScore > 5) then {
            private _patrolPos2 = _position getPos [50, random 360];
            private _grp2 = [_patrolPos2, _enemySide, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
            { _x setUnitLoadout (selectRandom GuerMenArray); removeHeadgear _x; } forEach units _grp2;
            _grp2 deleteGroupWhenEmpty true;
            [_grp2, _position, 200, 5, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp2]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        [_missionId] call FLO_fnc_sideMissionTaskCreate;
    }],
    
    // Success - stash destroyed
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _stash = (_instance get "data") getOrDefault ["stash", objNull];
        !isNull _stash && {!alive _stash}
    }],
    
    // Fail - officer escapes (moves too far from stash)
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _officer = _data getOrDefault ["officer", objNull];
        private _stash = _data getOrDefault ["stash", objNull];
        
        // Fail if officer is alive and moved >500m from stash
        if (!isNull _officer && {alive _officer} && {!isNull _stash}) then {
            if (_officer distance2D _stash > 500) exitWith { true };
        };
        
        false
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
    }]
];

_template
