/*
 * Function: FLO_fnc_templateSquadRescue
 * Author: Frontline Operations Development Group
 * Description:
 *   Template definition for the Squad Rescue side mission.
 *   Rescues a missing friendly squad from enemy territory.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
if !(_activeSide in [east, west]) then { _activeSide = west };
private _friendlyColor = if (_activeSide isEqualTo east) then { "colorOPFOR" } else { "colorBLUFOR" };

private _template = createHashMapFromArray [
    ["name", "Rescue Missing Squad"],
    ["description", "Intel suggests the whereabouts of a friendly squad we lost contact with. Track them down and rescue them."],
    ["icon", "mil_pickup"],
    ["color", _friendlyColor],
    ["cooldown", 900],
    ["timeout", 3600],
    ["maxActive", 1],
    ["reward", 100],
    ["isConvoy", false],
    
    // Setup function
    ["fnc_setup", {
        params ["_typeName"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        
        private _position = [0,0,0];
        private _canSpawn = false;
        
        // Find enemy-controlled objective only
        private _objId = [1500, getPos player, _enemySide] call FLO_fnc_getObjectiveNearPlayer;
        if (_objId == "") exitWith {
            [false, [0,0,0]]
        };

        _position = [_objId] call FLO_fnc_getRandomObjectivePos;
        
        private _house = [_position] call FLO_fnc_findMissionHouse;
        if (!isNull _house) then {
            _position = getPos _house;
            _canSpawn = true;
        };
        
        [_canSpawn, _position]
    }],
    
    // Spawn function
    ["fnc_spawn", {
        params ["_missionId"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _friendlySide = _activeSide;
        private _enemySide = if (_friendlySide isEqualTo east) then { west } else { east };
        private _friendlyKey = if (_friendlySide isEqualTo east) then { "EAST" } else { "WEST" };
        private _enemyKey = if (_enemySide isEqualTo east) then { "EAST" } else { "WEST" };
        private _factionCatalog = missionNamespace getVariable ["FLO_FactionCatalog", createHashMap];
        private _friendlyCatalog = _factionCatalog getOrDefault [_friendlyKey, createHashMap];
        private _enemyCatalog = _factionCatalog getOrDefault [_enemyKey, createHashMap];
        private _friendlyUnits = _friendlyCatalog getOrDefault ["units", ["B_Soldier_F", "B_Soldier_GL_F", "B_medic_F"]];
        private _enemyUnits = _enemyCatalog getOrDefault ["units", if (!isNil "East_Units") then { East_Units } else { ["O_Soldier_F"] }];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        private _house = nearestBuilding _position;
        if (isNull _house) exitWith {};
        
        private _buildingPos = _house buildingPos -1;
        if ((count _buildingPos) == 0) then { _buildingPos = [getPos _house]; };
        
        // Spawn intel composition
        ["Intel_MIS_01", selectRandom _buildingPos, [0,0,0], 0, false, false, true] call LARs_fnc_spawnComp;
        
        // Spawn captured squad (3-4 soldiers)
        private _squadUnits = [];
        private _squadCount = 3 + floor random 2;
        for "_i" from 1 to _squadCount do {
            private _unitType = selectRandom _friendlyUnits;
            private _grp = [selectRandom _buildingPos, _friendlySide, [_unitType]] call BIS_fnc_spawnGroup;
            private _unit = (units _grp) select 0;
            _unit setCaptive true;
            _unit disableAI "PATH";
            _unit playMoveNow (selectRandom ["Acts_AidlPsitMstpSsurWnonDnon01", "Acts_AidlPsitMstpSsurWnonDnon02"]);
            _squadUnits pushBack _unit;
            ["addEntity", [_missionId, _unit]] call FLO_fnc_sideMissionEntityTracker;
            
            // Add rescue action
            [
                _unit,
                "Rescue Squad Member",
                "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa",
                "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_unbind_ca.paa",
                "_this distance _target < 2",
                "_caller distance _target < 2",
                {},
                {},
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    _arguments params ["_missionId"];
                    
                    // Join group LOCALLY (Group Owner is Client)
                    [_target] join (group _caller);

                    [_missionId, _target] remoteExecCall ["FLO_fnc_sideMissionHandleRescue", 2];
                    
                    // Remove action locally and globally
                    [_target, _actionId] remoteExec ["BIS_fnc_holdActionRemove", 0];
                    
                    hint "Soldier Rescued!";
                },
                {},
                [_missionId],
                3,
                0,
                true,
                false
            ] remoteExec ["BIS_fnc_holdActionAdd", 0, _unit];
        };
        
        // Store squad reference
        private _data = _instance get "data";
        _data set ["squad", _squadUnits];
        _data set ["house", _house];
        _data set ["initialCount", count _squadUnits];
        _data set ["rescuedUnits", []];
        
        // Spawn garrison guards
        for "_i" from 1 to 4 do {
            private _grp = [selectRandom _buildingPos, _enemySide, [selectRandom _enemyUnits]] call BIS_fnc_spawnGroup;
            if (_i <= 2) then { ((units _grp) select 0) disableAI "PATH"; };
            _grp deleteGroupWhenEmpty true;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Spawn patrol
        private _patrolGrp = [getPos _house, _enemySide, [
            selectRandom _enemyUnits, selectRandom _enemyUnits,
            selectRandom _enemyUnits, selectRandom _enemyUnits
        ]] call BIS_fnc_spawnGroup;
        _patrolGrp deleteGroupWhenEmpty true;
        [_patrolGrp, getPos _house, 200, 5, "AWARE", "LIMITED"] call FLO_fnc_taskPatrol;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Extra patrols based on difficulty
        private _guardCount = 2 + (if (_aggrScore > 5) then {1} else {0}) + (if (_aggrScore > 10) then {1} else {0});
        for "_i" from 1 to _guardCount do {
            private _pos = _house getPos [20 + random 200, random 360];
            private _grp = [_pos, _enemySide, [selectRandom _enemyUnits]] call BIS_fnc_spawnGroup;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        if (_aggrScore > 10) then {
            private _patrolPos = _house getPos [100 + random 700, random 360];
            private _grp = [_patrolPos, _enemySide, [selectRandom _enemyUnits, selectRandom _enemyUnits, selectRandom _enemyUnits]] call BIS_fnc_spawnGroup;
            [_grp, getPos _house, 1000] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Create BIS task
        [_missionId] call FLO_fnc_sideMissionTaskCreate;
    }],
    
    // Success - at least half the squad rescued
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _initialCount = _data getOrDefault ["initialCount", 1];
        private _rescuedUnits = _data getOrDefault ["rescuedUnits", []];

        (count _rescuedUnits) >= ceil (_initialCount / 2)
    }],
    
    // Fail - all squad members killed
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _squad = _data getOrDefault ["squad", []];
        
        if ((count _squad) == 0) exitWith { false };
        
        ({ alive _x } count _squad) == 0
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
    }]
];

_template
