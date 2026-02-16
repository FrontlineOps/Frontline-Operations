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

private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
if !(_activeSide in [east, west]) then { _activeSide = west };
private _friendlyColor = if (_activeSide isEqualTo east) then { "colorOPFOR" } else { "colorBLUFOR" };

private _template = createHashMapFromArray [
    ["name", "Rescue POWs"],
    ["description", "Intel indicates a nearby POW camp. Rescue our captured forces and return them safely."],
    ["icon", "mil_pickup"],
    ["color", _friendlyColor],
    ["cooldown", 1200],
    ["timeout", 3600],
    ["maxActive", 1],
    ["reward", 100],
    ["isConvoy", false],
    
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
        _canSpawn = true;
        
        [_canSpawn, _position]
    }],
    
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
        private _friendlyUnits = _friendlyCatalog getOrDefault ["units", ["B_Soldier_F", "B_medic_F"]];
        private _enemyUnits = _enemyCatalog getOrDefault ["units", if (!isNil "East_Units") then { East_Units } else { ["O_Soldier_F"] }];
        private _enemyOfficers = _enemyCatalog getOrDefault ["officers", if (!isNil "East_Units_Officers") then { East_Units_Officers } else { _enemyUnits }];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _position = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        private _data = _instance get "data";
        
        // Find barracks-type building
        private _barracksSearch = nearestObjects [_position, [
            "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
            "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F", "HOUSE"
        ], 400];

        private _barracks = if ((count _barracksSearch) > 0) then { _barracksSearch select 0 } else { objNull };

        if (isNull _barracks) then { _barracks = nearestBuilding _position; };
        if (isNull _barracks) exitWith {
            ["SIDEMISSION", 1, format["POW Rescue %1: No suitable building found at %2", _missionId, _position]] call FLO_fnc_log;
        };

        private _buildingPos = _barracks buildingPos -1;
        if ((count _buildingPos) == 0) then { _buildingPos = [getPos _barracks]; };
        
        _data set ["barracks", _barracks];
        
        // Spawn POWs
        private _pows = [];
        private _powCount = 2 + floor random 3;
        for "_i" from 1 to _powCount do {
            private _unitType = selectRandom _friendlyUnits;
            private _grp = [selectRandom _buildingPos, _friendlySide, [_unitType]] call BIS_fnc_spawnGroup;
            private _unit = (units _grp) select 0;
            _unit setCaptive true;
            _unit disableAI "PATH";
            removeAllWeapons _unit;
            _pows pushBack _unit;
            ["addEntity", [_missionId, _unit]] call FLO_fnc_sideMissionEntityTracker;
            
            // Add rescue action
            [
                _unit,
                "Rescue POW",
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
                    
                    // Release unit REMOTELY (Unit Owner is Server)
                    [
                        _target,
                        {
                            if (!alive _this) exitWith {};
                            _this setCaptive false;
                            _this enableAI "PATH";
                            _this enableAI "MOVE";
                            _this enableAI "ANIM";
                            _this switchMove "";
                        }
                    ] remoteExec ["call", owner _target];
                    
                    // Remove action locally and globally
                    [_target, _actionId] remoteExec ["BIS_fnc_holdActionRemove", 0];
                    
                    hint "POW Rescued! Get them to safety.";
                },
                {},
                [_missionId],
                3,
                0,
                true,
                false
            ] remoteExec ["BIS_fnc_holdActionAdd", 0, _unit];
        };
        
        _data set ["pows", _pows];
        _data set ["initialCount", count _pows];
        
        // Spawn intel composition
        ["Intel_01", selectRandom _buildingPos, [0,0,0], 0, false, false, true] call LARs_fnc_spawnComp;
        
        // Spawn officer
        private _officerGrp = [selectRandom _buildingPos, _enemySide, [selectRandom _enemyOfficers]] call BIS_fnc_spawnGroup;
        private _officer = (units _officerGrp) select 0;
        _officer disableAI "PATH";
        ["addGroup", [_missionId, _officerGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Garrison guards
        private _garrisonCount = 2 + (if (_aggrScore > 5) then {2} else {0}) + (if (_aggrScore > 10) then {2} else {0});
        for "_i" from 1 to _garrisonCount do {
            private _grp = [selectRandom _buildingPos, _enemySide, [selectRandom _enemyUnits]] call BIS_fnc_spawnGroup;
            if (_i % 2 == 0) then { ((units _grp) select 0) disableAI "PATH"; };
            _grp deleteGroupWhenEmpty true;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        // Patrols
        private _patrolGrp = [_position getPos [50, random 360], _enemySide, [
            selectRandom _enemyUnits, selectRandom _enemyUnits, selectRandom _enemyUnits
        ]] call BIS_fnc_spawnGroup;
        [_patrolGrp, _position, 100] call BIS_fnc_taskPatrol;
        ["addGroup", [_missionId, _patrolGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        if (_aggrScore > 5) then {
            private _grp = [_position getPos [100, random 360], _enemySide, [
                selectRandom _enemyUnits, selectRandom _enemyUnits, selectRandom _enemyUnits
            ]] call BIS_fnc_spawnGroup;
            [_grp, _position, 200] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        if (_aggrScore > 10) then {
            private _grp = [_position getPos [150, random 360], _enemySide, [
                selectRandom _enemyUnits, selectRandom _enemyUnits, selectRandom _enemyUnits
            ]] call BIS_fnc_spawnGroup;
            [_grp, _position, 200] call BIS_fnc_taskPatrol;
            ["addGroup", [_missionId, _grp]] call FLO_fnc_sideMissionEntityTracker;
        };
        
        [_missionId] call FLO_fnc_sideMissionTaskCreate;
    }],
    
    // Success - at least half POWs rescued
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _friendlySide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_friendlySide in [east, west]) then { _friendlySide = west };
        private _data = _instance get "data";
        private _pows = _data getOrDefault ["pows", []];
        private _initialCount = _data getOrDefault ["initialCount", 1];
        
        private _rescued = {
            private _pow = _x;
            alive _pow && {!captive _pow} && {
                private _nearFriendlyPlayer = (allPlayers findIf { _x distance _pow < 50 }) >= 0;
                _nearFriendlyPlayer || {vehicle _pow != _pow && {side vehicle _pow == _friendlySide}}
            }
        } count _pows;
        
        _rescued >= (_initialCount / 2)
    }],
    
    // Fail - all POWs killed
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _pows = (_instance get "data") getOrDefault ["pows", []];
        (count _pows) > 0 && {({ alive _x } count _pows) == 0}
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
    }]
];

_template
