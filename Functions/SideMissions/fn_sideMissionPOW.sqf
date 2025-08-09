/*
 * Function: FLO_fnc_sideMissionPOW
 * Author: Frontline Operations Development Group
 * Description:
 *  Starts the POW rescue side mission.
 * Arguments: None
 * Returns: Nothing
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = ["Intel indicates a nearby POW camp. We can rescue our captured forces (Optional Mission: Rescue POWs)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

    if (_result) then {
        // Show a random enemy group instead of a marker reveal
        [player] call FLO_fnc_revealRandomEnemyGroup;
    };

    if (!_result) then {
        private _HQB = [player] call FLO_fnc_findMissionHouse;
        if (isNull _HQB) exitWith {};

        // Prefer an objective near players for the mission center; fallback to the found house
        private _objId = [4000, getPos player] call FLO_fnc_getObjectiveNearPlayer;
        private _centerPos = if (_objId != "") then { [_objId] call FLO_fnc_getRandomObjectivePos } else { getPos _HQB };

        private _markerName = format ["InvesMark_%1", floor diag_tickTime];
        private _mrkr = createMarker [_markerName, _centerPos];
        _mrkr setMarkerType "mil_warning";
        _mrkr setMarkerColor "colorOPFOR";
        _mrkr setMarkerSize [0.8, 0.8];

        missionNamespace setVariable ["FLO_fnc_inlinePOW", {
            params ["_thisPOWTrigger"];
            // Begin inlined POW mission
            private _thisPOWTrigger = _this select 0;

            // Get aggression score from marker
            private _AGGRSCORE = FLO_DifficultyHandle get "value";

            // Wait for barracks to spawn
            sleep 15;
            // Wait until we have at least one valid barracks near the center
            waitUntil {
                count (nearestObjects [_thisPOWTrigger, [
                    "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
                    "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F",
                    "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"
                ], 400]) > 0
            };

            private _barracks = nearestObjects [_thisPOWTrigger, [
                "Land_i_Barracks_V1_F", "Land_u_Barracks_V2_F", "Land_i_Barracks_V2_F",
                "Land_Barracks_01_grey_F", "Land_Barracks_01_dilapidated_F",
                "Land_vn_barracks_01_camo_f", "Land_Barracks_01_camo_F"
            ], 400];
            if (count _barracks == 0) exitWith {};
            private _Position = _barracks select 0;

            // Spawn officer with intel action
            private _bPos = _Position buildingPos -1;
            if (count _bPos == 0) then { _bPos = [getPos _Position]; };
            private _Pos = selectRandom _bPos;
            private _G = [_Pos, East, [selectRandom East_Units_Officers]] call BIS_fnc_spawnGroup;
            private _OFC = (units _G) select 0;
            _OFC disableAI "PATH";

            [
                _OFC,
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
            ] remoteExec ["BIS_fnc_holdActionAdd", 0, _OFC];

            // Spawn garrison units
            private _spawnGarrison = {
                params ["_pos", "_disablePath"];
                G = [_pos, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
                if (_disablePath) then {((units G) select 0) disableAI "PATH"};
                G deleteGroupWhenEmpty true;
            };

            // Garrison
            private _bldPos = _Position buildingPos -1;
            if (count _bldPos == 0) then { _bldPos = [getPos _Position]; };
            [selectRandom _bldPos, true] call _spawnGarrison;
            [selectRandom _bldPos, false] call _spawnGarrison;
            if (_AGGRSCORE > 5) then {
                [selectRandom (_Position buildingPos -1), true] call _spawnGarrison;
                [selectRandom (_Position buildingPos -1), false] call _spawnGarrison;
            };
            if (_AGGRSCORE > 10) then {
                [selectRandom (_Position buildingPos -1), true] call _spawnGarrison;
                [selectRandom (_Position buildingPos -1), false] call _spawnGarrison;
            };

            // Spawn guards in buildings
            private _allBuildings = nearestObjects [(getpos _thisPOWTrigger), [
                "House", "Land_MilOffices_V1_F", "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V2_F",
                "Land_Cargo_Tower_V1_F", "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V2_F", "Land_Cargo_HQ_V1_F",
                "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"
            ], 300];

            private _allPositions = [];
            {
                private _bps = _x buildingPos -1;
                if (count _bps > 0) then { _allPositions append _bps; };
            } forEach _allBuildings;
            if (count _allPositions == 0) then { _allPositions = [getPos _thisPOWTrigger]; };

            // Spawn intel
            ["Intel_01", selectRandom _allPositions, [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;

            // Spawn building guards
            private _spawnBuildingGuard = {
                params ["_disablePath"];
                G = [selectRandom _allPositions, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
                if (_disablePath) then {((units G) select 0) disableAI "PATH"};
                G deleteGroupWhenEmpty true;
            };

            // Building guards
            for "_i" from 1 to 4 do {
                [_i % 2 == 0] call _spawnBuildingGuard;
            };
            if (_AGGRSCORE > 5) then {
                for "_i" from 1 to 2 do {
                    [_i % 2 == 0] call _spawnBuildingGuard;
                };
            };
            if (_AGGRSCORE > 10) then {
                for "_i" from 1 to 2 do {
                    [_i % 2 == 0] call _spawnBuildingGuard;
                };
            };

            // Spawn patrol groups
            private _spawnPatrol = {
                params ["_angle", "_radius"];
                PRL = [(getPos _thisPOWTrigger) getPos [_radius, _angle], East, [
                    selectRandom East_Units, selectRandom East_Units, selectRandom East_Units,
                    selectRandom East_Units, selectRandom East_Units, selectRandom East_Units
                ]] call BIS_fnc_spawnGroup;
                [PRL, getpos _thisPOWTrigger, _radius] call BIS_fnc_taskPatrol;
                PRL deleteGroupWhenEmpty true;
            };

            // Patrols
            [50, 50] call _spawnPatrol;
            [50, 100] call _spawnPatrol;
            if (_AGGRSCORE > 5) then {
                [180, 200] call _spawnPatrol;
            };
            if (_AGGRSCORE > 10) then {
                [270, 200] call _spawnPatrol;
            };

            // Spawn vehicles
            private _spawnVehicle = {
                if (count [(getpos _thisPOWTrigger) nearRoads 70] > 0) then {
                    _nearRoad = selectRandom ((getpos _thisPOWTrigger) nearRoads 70);
                    _V = createVehicle [selectRandom East_Ground_Vehicles_Ambient, (_nearRoad getRelPos [0, 0]), [], 4, "NONE"];
                    _nextRoad = (roadsConnectedTo _nearRoad) select 0;
                    _V setDir (_nearRoad getDir _nextRoad);
                };
            };

            // Vehicles
            [] call _spawnVehicle;
            if (_AGGRSCORE > 5) then {[] call _spawnVehicle};

            // Spawn intel items
            [_thisPOWTrigger, 200] call FLO_fnc_addIntelItems;            // End inlined POW mission
        }];

        private _trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
        _trgA setTriggerArea [2000, 2000, 0, false, 60];
        _trgA setTriggerInterval 3;
        _trgA setTriggerTimeout [7, 7, 7, true];
        _trgA setTriggerActivation ["WEST", "PRESENT", false];
        _trgA setTriggerStatements [
            "this",
            "[thisTrigger] spawn (missionNamespace getVariable 'FLO_fnc_inlinePOW')",
            ""
        ];

        sleep 1;
        private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
        ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
    };
};
