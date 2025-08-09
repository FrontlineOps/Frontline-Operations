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
    ] call BIS_fnc_guiMessage;

    if (_result) then {
        [player] call FLO_fnc_revealRandomEnemyGroup;
    } else {
        [] spawn {
            if (ConVLocc == 0) then {
                sleep 10;

                private _AGGRSCORE = FLO_DifficultyHandle get "value";

                // Determine destination (front line) objective near players and a far-away start objective
                private _startPos = objNull;
                private _endPos = objNull;
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
                        private _farthest = "";
                        private _maxD = -1;
                        {
                            private _p = (FLO_Objectives get _x) get "position";
                            private _d = _p distance2D _destPosCenter;
                            if (_d > _maxD) then { _maxD = _d; _farthest = _x; };
                        } forEach _startCandidates;
                        _farthest
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
                }

                // Create convoy markers
                private _createMarker = {
                    params ["_name", "_pos", "_text"];
                    private _id = createMarker [_name, _pos];
                    _id setMarkerType "mil_marker_noShadow";
                    _id setMarkerColor "colorOPFOR";
                    _id setMarkerText _text;
                    _id setMarkerSize [1.5, 1.5];
                    _id setMarkerAlpha 0.7;
                    _id
                };

                // Create markers
                ["ConvoyStrt", _startPos, "Convoy Start"] call _createMarker;
                ["ConvoyDest", _endPos, "Convoy End"] call _createMarker;

                // Send notifications
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY3", "warning"] call FLO_fnc_sendNotification;
                sleep 600;
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY4", "warning"] call FLO_fnc_sendNotification;

                ConVLocc = 1;
                private _CNV = selectRandom (_startPos nearRoads 200);
                trg1 = 0;

                // Find control point
                private _CNTR = (nearestObjects [_endPos, [
                    "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F",
                    "Land_Cargo_House_V3_F", "House"
                ], 300]) select 0;

                // Create convoy vehicles
                private _createConvoyVehicle = {
                    params ["_vehicleType", "_pos", "_group"];
                    private _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                    private _vehicle = createVehicle [_vehicleType, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                    private _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                    _vehicle setDir _azimuth;
                    private _crewCount = [typeOf _vehicle, true] call BIS_fnc_crewCount;
                    private _crewGroup = [getPosATL _nearRoad, east, _crewCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny _vehicle } forEach units _crewGroup;
                    _vehicle setUnloadInCombat [true, false];
                    { [_x] join _group } forEach units _crewGroup;
                    _vehicle
                };

                // Create main convoy group
                private _crewCount = [selectRandom East_Ground_Vehicles_Light, true] call BIS_fnc_crewCount;
                missionNamespace setVariable ["CGM", [getPosATL _CNV, east, _crewCount] call BIS_fnc_spawnGroup, true];

                // Create vehicles
                V0 = [selectRandom East_Ground_Vehicles_Light, _startPos, CGM] call _createConvoyVehicle;
                waitUntil {((getMarkerPos "ConvoyStrt") distance (getPos V0)) > 600};
                V1 = [selectRandom East_Ground_Transport, _startPos, CGM] call _createConvoyVehicle;
                V2 = [selectRandom East_Ground_Vehicles_Light, _startPos, CGM] call _createConvoyVehicle;

                if (_AGGRSCORE > 5) then {
                    V3 = [selectRandom East_Ground_Transport, _startPos, CGM] call _createConvoyVehicle;
                    V4 = [selectRandom East_Ground_Vehicles_Light, _startPos, CGM] call _createConvoyVehicle;
                };

                if (_AGGRSCORE > 10) then {
                    V5 = [selectRandom East_Ground_Transport, _startPos, CGM] call _createConvoyVehicle;
                    V6 = [selectRandom East_Ground_Vehicles_Light, _startPos, CGM] call _createConvoyVehicle;
                };

                // Add kill event handlers
                private _addKillEH = {
                    params ["_vehicle"];
                    if (alive _vehicle) then {
                        private _mrkr = createMarker [str getPos _vehicle, getPos _vehicle];
                        _mrkr setMarkerType "mil_marker_noShadow";
                        _mrkr setMarkerText "DESTROY";
                        _mrkr setMarkerColor "colorOPFOR";
                        _mrkr setMarkerSize [0.9, 0.9];
                        _mrkr setMarkerAlpha 0.7;
                        _vehicle addEventHandler ["Killed", {
                            private _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                            private _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                            deleteMarker _M;
                        }];
                    };
                };

                { [_x] call _addKillEH } forEach [V0, V1, V2, V3, V4, V5, V6];

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
