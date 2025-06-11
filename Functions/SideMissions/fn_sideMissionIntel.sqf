/*
 * Function: FLO_fnc_sideMissionIntel
 * Author: Frontline Operations Development Group
 * Description:
 *  Starts the enemy intel gathering mission.
 * Arguments: None
 * Returns: Nothing
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = ["Reports hint at enemy plans stored nearby. Investigate to gather intel (Optional Mission: Recover Enemy Intel)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

    if (_result) then {
        [player] call FLO_fnc_revealRandomEnemyGroup;
    };

    if (!_result) then {
        private _HQB = [player] call FLO_fnc_findMissionHouse;
        if (isNull _HQB) exitWith {};

        private _markerName = format ["InvesMark_%1", floor diag_tickTime];
        private _mrkr = createMarker [_markerName, (getPos _HQB)];
        _mrkr setMarkerType "mil_unknown";
        _mrkr setMarkerColor "colorOPFOR";
        _mrkr setMarkerSize [0.8, 0.8];

        missionNamespace setVariable ["FLO_fnc_inlineIntelGather", {
            params [["_thisIntelTrigger", objNull]];
            // Begin inlined intel gather mission
            
            // Get aggression score
            private _AGGRSCORE = FLO_DifficultyHandle get "value";

            // Initialize configuration
            private _config = createHashMapFromArray [
                ["patrolRadius", 70],
                ["patrolOffset", [20, 30]],
                ["unitCount", 5],
                ["searchRadius", 500],
                ["compRadius", 40]
            ];

            // Helper function to spawn patrol group
            private _fnc_spawnPatrol = {
                params ["_pos", "_offset"];
                private _spawnPos = _pos getPos [(_offset select 0) + random (_offset select 1), random 360];
                private _units = [];
                for "_i" from 1 to (_config get "unitCount") do {
                    _units pushBack (selectRandom East_Units);
                };
                private _group = [_spawnPos, East, _units] call BIS_fnc_spawnGroup;
                [_group, _pos, _config get "patrolRadius"] call BIS_fnc_taskPatrol;
                _group deleteGroupWhenEmpty true;
                _group
            };

            // Spawn initial recon position
            private _mount = (nearestLocations [getPos _thisIntelTrigger, ["Mount"], _config get "searchRadius"]) select 0;
            private _pos = locationPosition _mount;

            ["Recon_OPF_1", _pos, [0,0,0], 0, true] call LARs_fnc_spawnComp;
            sleep 5;

            // Set unit loadouts
            {
                _x setUnitLoadout (selectRandom East_Units);
            } forEach nearestObjects [_pos, ["Man"], _config get "compRadius"];

            // Setup map board
            private _mapBoard = nearestObjects [_pos, ["MapBoard_altis_F"], _config get "compRadius"] select 0;
            publicVariable "MapBooard";
            removeAllActions _mapBoard;

            // Add investigation action
            [
                _mapBoard,
                [
                    "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Investigate Enemy Plans",
                    {
                        params ["_target"];
                        [_target] call FLO_fnc_militaryIntel;
                        _target removeAction (_this select 2);

                        private _markers = allMapMarkers select {markerType _x == "o_recon"};
                        private _nearestMarker = [_markers, _target] call BIS_fnc_nearestPosition;
                        deleteMarker _nearestMarker;

                        [30, "STR_FLO_RECONSITE"] call FLO_fnc_sendRewardNotification;
                        [30] call FLO_fnc_addReward;
                        [-0.35, "decrease"] call FLO_fnc_adjustAggression;
                    },
                    nil,
                    1.5,
                    true,
                    true,
                    "",
                    "alive _target",
                    4,
                    false,
                    "",
                    ""
                ]
            ] remoteExec ["addAction", 0, true];

            // Spawn initial patrol
            [_pos, _config get "patrolOffset"] call _fnc_spawnPatrol;

            // Spawn additional positions based on aggression score
            if (_AGGRSCORE > 5) then {
                private _mount2 = selectRandom nearestLocations [getPos _thisIntelTrigger, ["Mount"], _config get "searchRadius"];
                private _pos2 = locationPosition _mount2;

                ["Watchpost_8", _pos2, [0,0,0], 0, true] call LARs_fnc_spawnComp;
                {
                    _x setUnitLoadout (selectRandom East_Units);
                } forEach nearestObjects [_pos2, ["Man"], _config get "compRadius"];

                [_pos2, _config get "patrolOffset"] call _fnc_spawnPatrol;
            };

            if (_AGGRSCORE > 10) then {
                private _mount3 = selectRandom nearestLocations [getPos _thisIntelTrigger, ["Mount"], _config get "searchRadius"];
                private _pos3 = locationPosition _mount3;

                ["Recon_OPF_3", _pos3, [0,0,0], 0, true] call LARs_fnc_spawnComp;
                {
                    _x setUnitLoadout (selectRandom East_Units);
                } forEach nearestObjects [_pos3, ["Man"], _config get "compRadius"];

                [_pos3, _config get "patrolOffset"] call _fnc_spawnPatrol;
            };

            // Remove non-west units from Zeus
            {
                if !(side _x == west) then {
                    ZEUS removeCuratorEditableObjects [[_x], true];
                };
            } forEach allUnits;

            // Spawn intel items
            [_thisIntelTrigger, 300] call FLO_fnc_addIntelItems;
            // End inlined intel gather mission
        }];

        private _trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
        _trgA setTriggerArea [2000, 2000, 0, false, 60];
        _trgA setTriggerInterval 3;
        _trgA setTriggerTimeout [7, 7, 7, true];
        _trgA setTriggerActivation ["WEST", "PRESENT", false];
        _trgA setTriggerStatements [
            "this",
            "[thisTrigger] spawn (missionNamespace getVariable 'FLO_fnc_inlineIntelGather')",
            "",
            ""
        ];

        sleep 1;
        private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
        ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
    };
};
