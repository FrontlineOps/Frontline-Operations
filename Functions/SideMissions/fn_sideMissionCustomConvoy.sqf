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
                private _startPos = player getPos [1500 + random 1000, random 360];
                private _endPos = _startPos getPos [2000 + random 1000, random 360];

                // Create convoy markers
                private _createMarker = {
                    params ["_name", "_pos", "_text"];
                    private _mrkr = createMarker [_name, _pos];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerText _text;
                    _mrkr setMarkerSize [1.5, 1.5];
                    _mrkr setMarkerAlpha 0.7;
                    _mrkr
                };

                [_createMarker, "ConvoyStrt", _startPos, "Convoy Start"] call _createMarker;
                [_createMarker, "ConvoyDest", _endPos, "Convoy End"] call _createMarker;

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
