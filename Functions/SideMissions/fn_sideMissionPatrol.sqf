/*
 * Function: FLO_fnc_sideMissionPatrol
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts a mission to disrupt a roaming enemy patrol.
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = [
        "Enemy patrols are active nearby. We can track and eliminate them (Optional Mission: Disrupt Patrol)",
        "", _DVRT, _GNRT, nil, false, false
    ] call FLO_fnc_safeConfirm;

    if (_result) then {
        [player] call FLO_fnc_revealRandomEnemyGroup;
    } else {
        private _trg = createTrigger ["EmptyDetector", position player];
        [_trg] spawn {
            params ["_thisPatrolTrigger"];
            
            // Get aggression score from marker
            private _aggrScore = FLO_DifficultyHandle get "value";
            
            private _targetBuilding = [getPos _thisPatrolTrigger] call FLO_fnc_findMissionHouse;
            if (isNull _targetBuilding) exitWith {};
            
            // Create objective stash
            private _stashPos = selectRandom (_targetBuilding buildingPos -1);
            private _stash = createVehicle ["Box_FIA_Ammo_F", _stashPos, [], 500, "NONE"];
            _stash allowDamage false;
            _stash setPos _stashPos;
            sleep 3;
            _stash allowDamage true;
            
            // Add stash destruction handler
            _stash addEventHandler ["Killed", {
                private _missionMarkers = allMapMarkers select {markerText _x == "Mission : Counter Insurgency"};
                private _nearestMarker = [_missionMarkers, (_this select 0)] call BIS_fnc_nearestPosition;
                deleteMarker _nearestMarker;
                
                ["ScoreAdded", ["Insurgent Stash Destroyed", 30]] call BIS_fnc_showNotification;
                [30] call FLO_fnc_addReward;
                [-0.35, "decrease"] call FLO_fnc_adjustAggression;
                playMusic "EventTrack01_F_Curator";
            }];
            
            // Spawn officer with intel
            private _officerPos = selectRandom (_targetBuilding buildingPos -1);
            private _officerGroup = [_officerPos, East, [selectRandom East_Units_Officers]] call BIS_fnc_spawnGroup;
            private _officer = (units _officerGroup) select 0;
            _officer disableAI "PATH";
            
            // Add intel action to officer
            [
                _officer,
                "Search Officer",
                "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa",
                "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa",
                "(_this distance _target)<2",
                "(_this distance _target)<2",
                {playSound3D ["a3\missions_f_oldman\data\sound\intel_body\1sec\intel_body_1sec_02.wss", (_this select 0)]},
                {},
                {[] call FLO_fnc_militaryIntel},
                {},
                [],
                3,
                0,
                true,
                false
            ] remoteExec ["BIS_fnc_holdActionAdd", 0, _officer];
            
            // Function to create insurgent unit
            private _createInsurgent = {
                params ["_pos", "_disablePath"];
                private _group = [_pos, East, [selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
                {
                    private _uniform = uniform _x;
                    _x setUnitLoadout (selectRandom GuerMenArray);
                    removeHeadgear _x;
                    _x forceAddUniform _uniform;
                } forEach units _group;
                if (_disablePath) then {
                    ((units _group) select 0) disableAI "PATH";
                };
                _group
            };
            
            // Get nearby buildings for garrison
            private _nearbyBuildings = nearestObjects [getPos _targetBuilding, ["HOUSE"], 200];
            private _validBuildings = _nearbyBuildings select {count (_x buildingPos -1) > 0};
            
            // Spawn garrison units
            for "_i" from 1 to 3 do {
                private _pos = selectRandom (_targetBuilding buildingPos -1);
                [_pos, true] call _createInsurgent;
            };
            
            // Spawn additional units based on aggression score
            if (_aggrScore > 5) then {
                private _extraBuilding = selectRandom _validBuildings;
                for "_i" from 1 to 3 do {
                    private _pos = selectRandom (_extraBuilding buildingPos -1);
                    [_pos, true] call _createInsurgent;
                };
            };
            
            if (_aggrScore > 10) then {
                private _extraBuilding = selectRandom _validBuildings;
                for "_i" from 1 to 3 do {
                    private _pos = selectRandom (_extraBuilding buildingPos -1);
                    [_pos, true] call _createInsurgent;
                };
            };
            
            // Spawn guard units
            private _extra5 = if (_aggrScore > 5) then {1} else {0};
            private _extra10 = if (_aggrScore > 10) then {1} else {0};
            for "_i" from 1 to (1 + _extra5 + _extra10) do {
                private _guardPos = [getPos _targetBuilding, 10, 30, 5, 1, 0] call BIS_fnc_findSafePos;
                [_guardPos, true] call _createInsurgent;
            };
            
            // Spawn patrol groups
            private _patrolPos = (getPos _targetBuilding) getPos [30, 50];
            private _patrolGroup = [_patrolPos, East, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
            {
                private _uniform = uniform _x;
                _x setUnitLoadout (selectRandom GuerMenArray);
                removeHeadgear _x;
                _x forceAddUniform _uniform;
            } forEach units _patrolGroup;
            [_patrolGroup, getPos _targetBuilding, 20] call BIS_fnc_taskPatrol;
            
            if (_aggrScore > 5) then {
                private _patrolPos = (getPos _targetBuilding) getPos [30, 180];
                private _patrolGroup = [_patrolPos, East, [selectRandom CivMenArray, selectRandom CivMenArray]] call BIS_fnc_spawnGroup;
                {
                    private _uniform = uniform _x;
                    _x setUnitLoadout (selectRandom GuerMenArray);
                    removeHeadgear _x;
                    _x forceAddUniform _uniform;
                } forEach units _patrolGroup;
                [_patrolGroup, getPos _targetBuilding, 200] call BIS_fnc_taskPatrol;
            };
            
            // Spawn vehicles based on aggression score
            if (_aggrScore > 5 && {count [(getPos _targetBuilding) nearRoads 70] > 0}) then {
                private _nearRoad = selectRandom ((getPos _targetBuilding) nearRoads 70);
                private _vehicle = createVehicle [selectRandom CivVehArray, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"];
                private _nextRoad = (roadsConnectedTo _nearRoad) select 0;
                _vehicle setDir (_nearRoad getDir _nextRoad);
            };
            
            if (_aggrScore > 10 && {count [(getPos _targetBuilding) nearRoads 70] > 0}) then {
                private _nearRoad = selectRandom ((getPos _targetBuilding) nearRoads 70);
                private _vehicle = createVehicle [selectRandom CivVehArray, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"];
                private _nextRoad = (roadsConnectedTo _nearRoad) select 0;
                _vehicle setDir (_nearRoad getDir _nextRoad);
            };
            
            // Remove units from Zeus
            {
                if !(side _x == west) then {
                    ZEUS removeCuratorEditableObjects [[_x], true];
                };
            } forEach allUnits;
        };
    };
};
