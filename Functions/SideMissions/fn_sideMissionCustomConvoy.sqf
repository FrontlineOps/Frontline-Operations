/*
 * Function: FLO_fnc_sideMissionCustomConvoy
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts a special convoy interdiction mission.
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = [
        "A high value enemy convoy is on the move. We can ambush it (Optional Mission: Intercept Convoy)",
        "", _DVRT, _GNRT, nil, false, false
    ] call FLO_fnc_safeConfirm;

    if (_result) then {
        [player] call FLO_fnc_revealRandomEnemyGroup;
    } else {
        [] spawn {
            if (ConVLocc == 0) then {
                sleep 10;

                private _AGGRSCORE = FLO_DifficultyHandle get "value";

                // Determine destination (front line) objective near players and a far-away start objective
                private _startPos = [0,0,0];
                private _endPos = [0,0,0];
                if (!isNil "FLO_Objectives" && {count (keys FLO_Objectives) > 0}) then {
                    private _players = allPlayers;
                    private _frontlineMaxDist = 4000; // near players
                    private _minStartDist = 6000;     // far from frontline

                    // Choose frontline objective near players
                    // Destination objective near players (frontline)
                    private _destObjId = [_frontlineMaxDist, if (count _players > 0) then { getPos (selectRandom _players) } else { getPos player }] call FLO_fnc_getObjectiveNearPlayer;

                    private _destData = FLO_Objectives get _destObjId;
                    private _destPosCenter = if (!isNil "_destData") then { _destData get "position" } else { getPos player };

                    // Choose start objective far away from destination
                    private _startCandidates = (keys FLO_Objectives) select {
                        _x != _destObjId && {
                            private _p = (FLO_Objectives get _x) get "position";
                            (_p distance2D _destPosCenter) >= _minStartDist
                        }
                    };
                    private _startObjId = if (count _startCandidates > 0) then {
                        selectRandom _startCandidates
                    } else {
                        selectRandom (keys FLO_Objectives)
                    };

                    _startPos = [_startObjId] call FLO_fnc_getRandomObjectivePos;
                    _endPos = [_destObjId] call FLO_fnc_getRandomObjectivePos;
                } else {
                    // Fallback if objectives are not available
                    private _tmpStart = player getPos [1500 + random 1000, random 360];
                    _startPos = _tmpStart;
                    _endPos = _tmpStart getPos [2000 + random 1000, random 360];
                };

                // Ensure start/end are on roads (not water) and prepare markers
                private _findRoadNear = {
                    params ["_pos", ["_radius", 800], ["_attempts", 6]];
                    private _road = objNull;
                    private _rad = _radius;
                    for "_i" from 1 to _attempts do {
                        private _roads = _pos nearRoads _rad;
                        if (count _roads > 0) then {
                            // sort by distance
                            private _pairs = _roads apply { [_x, _pos distance2D (getPosATL _x)] };
                            _pairs sort true;
                            private _cand = (_pairs select 0) select 0;
                            private _rp = getPosATL _cand;
                            if !(surfaceIsWater _rp) exitWith { _road = _cand; };
                        };
                        _rad = _rad + 250;
                    };
                    _road
                };

                private _startRoad = [_startPos, 800, 6] call _findRoadNear;
                private _endRoad   = [_endPos,   800, 6] call _findRoadNear;
                if (isNull _startRoad || {isNull _endRoad}) exitWith { ConVLocc = 0; };

                _startPos = getPosATL _startRoad;
                _endPos   = getPosATL _endRoad;

                // Marker helper
                private _createMarker = {
                    params ["_name", "_pos", "_text"];
                    private _id = createMarker [_name, _pos];
                    _id setMarkerType "mil_marker_noShadow";
                    _id setMarkerColor "colorOPFOR";
                    _id setMarkerText _text;
                    _id setMarkerSize [1.5, 1.5];
                    _id setMarkerAlpha 0.7;
                };

                // Create markers
                ["ConvoyStrt", _startPos, "Convoy Start"] call _createMarker;
                ["ConvoyDest", _endPos, "Convoy End"] call _createMarker;

                // Send notifications
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY3", "warning"] call FLO_fnc_sendNotification;
                sleep 600;
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY4", "warning"] call FLO_fnc_sendNotification;

                ConVLocc = 1;
                private _CNV = _startRoad;
                trg1 = 0;

                // Find control point
                private _CNTR = (nearestObjects [_endPos, [
                    "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F",
                    "Land_Cargo_House_V3_F", "House"
                ], 300]) select 0;

                // Create convoy vehicles
                private _createConvoyVehicle = {
                    params ["_vehicleType", "_spawnPos", "_group", "_dir"];
                    private _vehicle = createVehicle [_vehicleType, _spawnPos, [], 10, "NONE"];
                    _vehicle setDir _dir;
                    private _crewCount = [typeOf _vehicle, true] call BIS_fnc_crewCount;
                    private _crewGroup = [_spawnPos, east, _crewCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny _vehicle } forEach units _crewGroup;
                    _vehicle setUnloadInCombat [true, false];
                    { [_x] join _group } forEach units _crewGroup;
                    _vehicle
                };

                // Create main convoy group
                private _crewCount = [selectRandom East_Ground_Vehicles_Light, true] call BIS_fnc_crewCount;
                missionNamespace setVariable ["CGM", [getPosATL _CNV, east, _crewCount] call BIS_fnc_spawnGroup, true];

                // Compute road direction and spawn slots along the road (lined up)
                private _nextRoad = (roadsConnectedTo _startRoad) select 0;
                private _spawnDir = if (!isNil "_nextRoad" && {!isNull _nextRoad}) then { _startRoad getDir _nextRoad } else { getDir _CNV };
                private _basePos = getPosATL _startRoad;
                private _spacing = 12; // meters between vehicles
                private _slots = [];
                for "_i" from 0 to 6 do { _slots pushBack (_basePos getPos [_i * _spacing, (_spawnDir + 180)]); };

                // Create vehicles
                V0 = [selectRandom East_Ground_Vehicles_Light, _slots select 0, CGM, _spawnDir] call _createConvoyVehicle;
                V1 = [selectRandom East_Ground_Transport,       _slots select 1, CGM, _spawnDir] call _createConvoyVehicle;
                V2 = [selectRandom East_Ground_Vehicles_Light,   _slots select 2, CGM, _spawnDir] call _createConvoyVehicle;

                if (_AGGRSCORE > 5) then {
                    V3 = [selectRandom East_Ground_Transport,     _slots select 3, CGM, _spawnDir] call _createConvoyVehicle;
                    V4 = [selectRandom East_Ground_Vehicles_Light,_slots select 4, CGM, _spawnDir] call _createConvoyVehicle;
                };

                if (_AGGRSCORE > 10) then {
                    V5 = [selectRandom East_Ground_Transport,     _slots select 5, CGM, _spawnDir] call _createConvoyVehicle;
                    V6 = [selectRandom East_Ground_Vehicles_Light,_slots select 6, CGM, _spawnDir] call _createConvoyVehicle;
                };

                // Collect spawned convoy vehicles (some may be undefined based on difficulty)
                private _vehicles = [];
                { if (!isNil _x) then { _vehicles pushBack (call compile _x); }; } forEach ["V0","V1","V2","V3","V4","V5","V6"];

                // Add kill event handlers per vehicle
                private _addKillEH = {
                    params ["_veh"];
                    if (!isNull _veh && {alive _veh}) then {
                        private _mName = format ["CNV_M_%1", netId _veh];
                        private _mrkr = createMarker [_mName, getPos _veh];
                        _mrkr setMarkerType "mil_marker_noShadow";
                        _mrkr setMarkerText "DESTROY";
                        _mrkr setMarkerColor "colorOPFOR";
                        _mrkr setMarkerSize [0.9, 0.9];
                        _mrkr setMarkerAlpha 0.7;
                        _veh addEventHandler ["Killed", {
                            params ["_killed"];
                            deleteMarker format ["CNV_M_%1", netId _killed];
                        }];
                    };
                };

                { [_x] call _addKillEH } forEach _vehicles;

                // Add unit kill event handlers
                {
                    _x addEventHandler ["Killed", {
                        private _Veh = nearestObjects [(_this select 0), ["LandVehicle"], 100] select 0;
                        ConVLocc = 0.5;
                        { 
                            _x removeAllEventHandlers "Killed";
                            [_x] orderGetIn false;
                            [_x] allowGetIn false;
                            unassignVehicle _x;
                            doGetOut _x;
                            _x allowDamage true;
                        } forEach units group ((crew _Veh) select 0);
                        [50] call FLO_fnc_addReward;
                        deleteMarker 'ConvoyStrt';
                        deleteMarker 'ConvoyDest';
                        [50, "STR_FLO_SUPPORTCONVOY"] call FLO_fnc_sendRewardNotification;
                    }];
                } forEach units CGM;

                // Create completion trigger
                private _TRGT = createTrigger ["EmptyDetector", [0,0,0]];
                _TRGT setTriggerArea [1,1,0,false,1];
                _TRGT setTriggerActivation ["NONE", "PRESENT", false];
                _TRGT setTriggerStatements [
                    "(!alive V0 && !alive V1 && !alive V2) or (!alive V0 && !alive V1 && !alive V2 && !alive V3 && !alive V4) or (!alive V0 && !alive V1 && !alive V2 && !alive V3 && !alive V4 && !alive V5 && !alive V6)",
                    "[100] call FLO_fnc_addReward; [100, 'STR_FLO_SUPPORTCONVOY'] call FLO_fnc_sendRewardNotification; ConVLocc = 0;",
                    ""
                ];

                // Add intel items to random units
                private _INTSTF = ["FlashDisk","FilesSecret","SmartPhone","DocumentsSecret"];
                private _INTENMALL = units CGM;
                private _INTENMCNT = count _INTENMALL;
                private _INTENMCNTNEW = round (_INTENMCNT / 2);
                private _INTENMALLNEW = _INTENMALL call BIS_fnc_arrayShuffle;
                private _INTENMSEL = _INTENMALLNEW select [0, _INTENMCNTNEW];
                { _x addItem selectRandom _INTSTF } forEach _INTENMSEL;
            };
        };
    };
};
