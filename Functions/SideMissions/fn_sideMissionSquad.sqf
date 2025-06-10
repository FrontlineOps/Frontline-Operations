/*
 * Function: FLO_fnc_sideMissionSquad
 * Author: Frontline Operations Development Group
 * Description:
 *  Starts the missing squad rescue mission extracted from the old
 *  militaryIntel.sqf logic.
 * Arguments: None
 * Returns: Nothing
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = ["Intel Suggest the whereabouts of the Friendly Squad we Lost Contact with Earlier, We can Track them down and Rescue Them,  (Optional Mission : Rescue Missing Squad)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

    if (_result) then {
        // Reveal a random enemy group for the players
        [player] call FLO_fnc_revealRandomEnemyGroup;
    };

    if (!_result) then {
        private _HQB = [player] call FLO_fnc_findMissionHouse;
        if (isNull _HQB) exitWith {};

        // Create marker with optimized format string
        private _mrkr = createMarker [format ["InvesMark_%1", floor diag_tickTime], getPos _HQB];
        _mrkr setMarkerType "mil_warning";
        _mrkr setMarkerColor "colorOPFOR";
        _mrkr setMarkerSize [0.8, 0.8];

        // Define inline squad function
        missionNamespace setVariable ["FLO_fnc_inlineSquad", {
            params ["_thisSquadTrigger"];
            
            // Get difficulty score once
            private _AGGRSCORE = FLO_DifficultyHandle get "value";
            
            // marker filtering with pre-defined array
            private _objective = [FLO_Objectives] call FLO_fnc_getRandomObjective;
            private _allMarks = _objective get "structures";
            
            // Pre-allocate and batch process house positions
            private _NOSHs = [];
            _NOSHs resize (count _allMarks * 5);
            {
                _NOSHs append (nearestObjects [getMarkerPos _x, ["HOUSE"], 400]);
            } forEach _allMarks;
            
            // Find HQ building with single query
            private _SHs = nearestObjects [_thisSquadTrigger, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
            private _HQB = (_SHs - _NOSHs) select 0;
            private _buildingPositions = _HQB buildingPos -1;
            
            // Spawn intel with cached position
            ["Intel_MIS_01", selectRandom _buildingPositions, [0,0,0], 0, false, false, true] call LARs_fnc_spawnComp;
            
            // Optimize garrison spawning with batch processing
            private _garrisonGroups = [];
            {
                private _group = [selectRandom _buildingPositions, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
                if (_forEachIndex < 2) then {
                    (units _group select 0) disableAI "PATH";
                };
                _garrisonGroups pushBack _group;
            } forEach [1,2,3,4];
            
            // Spawn patrol with optimized group creation
            private _patrolGroup = [getPos _HQB, East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
            [_patrolGroup, getPos _HQB, 200] call BIS_fnc_taskPatrol;
            
            // Spawn guards with optimized count calculation
            private _guardCount = 2 + (_AGGRSCORE > 5) + (_AGGRSCORE > 10);
            for "_i" from 1 to _guardCount do {
                private _pos = _HQB getPos [20 + random 200, random 360];
                [East, [selectRandom East_Units], _pos] call BIS_fnc_spawnGroup;
            };
            
            // Spawn additional patrols with optimized position calculation
            private _patrolPos = _HQB getPos [100 + random 700, random 360];
            private _patrolGroup2 = [East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units], _patrolPos] call BIS_fnc_spawnGroup;
            [_patrolGroup2, getPos _HQB, 500] call BIS_fnc_taskPatrol;
            
            if (_AGGRSCORE > 10) then {
                private _patrolPos2 = _HQB getPos [100 + random 700, random 360];
                private _patrolGroup3 = [East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units], _patrolPos2] call BIS_fnc_spawnGroup;
                [_patrolGroup3, getPos _HQB, 1000] call BIS_fnc_taskPatrol;
            };
        }];

        // Create trigger with optimized parameters
        private _trgA = createTrigger ["EmptyDetector", getPos _HQB];
        _trgA setTriggerArea [2000, 2000, 0, false, 60];
        _trgA setTriggerInterval 3;
        _trgA setTriggerTimeout [7, 7, 7, true];
        _trgA setTriggerActivation ["WEST", "PRESENT", false];
        _trgA setTriggerStatements [
            "this",
            "[thisTrigger] spawn (missionNamespace getVariable 'FLO_fnc_inlineSquad')",
            "",
            ""
        ];

        // Send notification with optimized grid position calculation
        ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", mapGridPosition getMarkerPos _mrkr], "info"] call FLO_fnc_sendNotification;
    };
};
