/*
 * Function: FLO_fnc_sideMissionConvoy
 * Author: Frontline Operations Development Group
 * Description:
 *  Starts the enemy convoy interception mission extracted from the old
 *  militaryIntel.sqf logic.
 * Arguments: None
 * Returns: Nothing
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = ["Intel Suggests Enemy Support Convoy will be Launched toward Frontlines, We can Intercept the Convoy and Dismantle their Reinforcements and Support operation,  (Optional Mission : Destroy Enemy Convoy)", "", _DVRT, _GNRT,nil, false, false] call BIS_fnc_guiMessage;

    if (_result) then {
        // Reveal intel on a nearby enemy convoy group
        [player] call FLO_fnc_revealRandomEnemyGroup;
    };

    if (!_result) then {
        [] spawn {
            if (ConVLocc == 0) then {
                sleep 10;

                _mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
                _mrkr = _mrkrs select 0;
                _AGGRSCORE = parseNumber (markerText _mrkr);

                private _startPos = player getPos [1500 + random 1000, random 360];
                private _endPos   = _startPos getPos [2000 + random 1000, random 360];

                _markerName = "ConvoyStrt";
                _mrkr = createMarker [_markerName, _startPos];
                _mrkr setMarkerType "mil_marker_noShadow";
                _mrkr setMarkerColor "colorOPFOR";
                _mrkr setMarkerText "Convoy Start";
                _mrkr setMarkerSize [1.5, 1.5];
                _mrkr setMarkerAlpha 0.7;

                _markerName = "ConvoyDest";
                _mrkr = createMarker [_markerName, _endPos];
                _mrkr setMarkerType "mil_marker_noShadow";
                _mrkr setMarkerColor "colorOPFOR";
                _mrkr setMarkerText "Convoy End";
                _mrkr setMarkerSize [1.5, 1.5];
                _mrkr setMarkerAlpha 0.7;

                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY3", "warning"] call FLO_fnc_sendNotification;
                sleep 600;
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY4", "warning"] call FLO_fnc_sendNotification;

                ConVLocc = 1;
                _Chance = selectRandom [1, 2, 3];
                _CNV = selectRandom (_startPos nearRoads 200);
                trg1 = 0;

                _CNTR = (nearestObjects [_endPos, [
                    "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F",
                    "Land_Cargo_House_V3_F", "House"
                ], 300]) select 0;

                _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                V0 = createVehicle [selectRandom East_Ground_Vehicles_Light, _nearRoad getRelPos [0, 0], [], 10, "NONE"];
                _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                V0 setDir _azimuth;
                _SCount = [typeOf V0, true] call BIS_fnc_crewCount;
                missionNamespace setVariable ["CGM", [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup, true];
                { _x moveInAny V0 } forEach units CGM;
                V0 setUnloadInCombat [true, false];

                waitUntil {((getMarkerPos "ConvoyStrt") distance (getPos V0)) > 600};

                _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                V1 = createVehicle [selectRandom East_Ground_Transport, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                V1 setDir _azimuth;
                _SCount = [typeOf V1, true] call BIS_fnc_crewCount;
                _CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
                { _x moveInAny V1 } forEach units _CG;
                V1 setUnloadInCombat [true, false];
                { [_x] join CGM } forEach units _CG;

                _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                V2 = createVehicle [selectRandom East_Ground_Vehicles_Light, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                V2 setDir _azimuth;
                _SCount = [typeOf V2, true] call BIS_fnc_crewCount;
                _CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
                { _x moveInAny V2 } forEach units _CG;
                V2 setUnloadInCombat [true, false];
                { [_x] join CGM } forEach units _CG;

                if (_AGGRSCORE > 5) then {
                    _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                    V3 = createVehicle [selectRandom East_Ground_Transport, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                    _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                    V3 setDir _azimuth;
                    _SCount = [typeOf V3, true] call BIS_fnc_crewCount;
                    _CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny V3 } forEach units _CG;
                    V3 setUnloadInCombat [true, false];
                    { [_x] join CGM } forEach units _CG;

                    _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                    V4 = createVehicle [selectRandom East_Ground_Vehicles_Light, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                    _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                    V4 setDir _azimuth;
                    _SCount = [typeOf V4, true] call BIS_fnc_crewCount;
                    _CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny V4 } forEach units _CG;
                    V4 setUnloadInCombat [true, false];
                    { [_x] join CGM } forEach units _CG;
                };

                if (_AGGRSCORE > 10) then {
                    _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                    V5 = createVehicle [selectRandom East_Ground_Transport, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                    _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                    V5 setDir _azimuth;
                    _SCount = [typeOf V5, true] call BIS_fnc_crewCount;
                    _CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny V5 } forEach units _CG;
                    V5 setUnloadInCombat [true, false];
                    { [_x] join CGM } forEach units _CG;

                    _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                    V6 = createVehicle [selectRandom East_Ground_Vehicles_Light, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                    _azimuth = getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest";
                    V6 setDir _azimuth;
                    _SCount = [typeOf V6, true] call BIS_fnc_crewCount;
                    _CG = [getPosATL _nearRoad, east, _SCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny V6 } forEach units _CG;
                    V6 setUnloadInCombat [true, false];
                    { [_x] join CGM } forEach units _CG;
                };

                {
                    _x addEventHandler ["Killed", {
                        _Veh = nearestObjects [(_this select 0), ["LandVehicle"], 100] select 0;
                        ConVLocc = 0.5;
                        { _x removeAllEventHandlers "Killed"; [_x] orderGetIn false; [_x] allowGetIn false; unassignVehicle _x; doGetOut _x; _x allowDamage true; } forEach units group ((crew _Veh) select 0);
                        [50] call FLO_fnc_addReward;
                        deleteMarker 'ConvoyStrt';
                        deleteMarker 'ConvoyDest';
                        [50, "STR_FLO_SUPPORTCONVOY"] call FLO_fnc_sendRewardNotification;
                    }];
                } forEach units CGM;

                if (alive V0) then {
                    _mrkr = createMarker [str getPos V0, getPos V0];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V0 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                if (alive V1) then {
                    _mrkr = createMarker [str getPos V1, getPos V1];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V1 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                if (alive V2) then {
                    _mrkr = createMarker [str getPos V2, getPos V2];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V2 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                if (alive V3) then {
                    _mrkr = createMarker [str getPos V3, getPos V3];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V3 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                if (alive V4) then {
                    _mrkr = createMarker [str getPos V4, getPos V4];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V4 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                if (alive V5) then {
                    _mrkr = createMarker [str getPos V5, getPos V5];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V5 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                if (alive V6) then {
                    _mrkr = createMarker [str getPos V6, getPos V6];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerText "DESTROY";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerSize [0.9, 0.9];
                    _mrkr setMarkerAlpha 0.7;
                    V6 addEventHandler ["Killed", {
                        _MMarks = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                        _M = [_MMarks, (_this select 0)] call BIS_fnc_nearestPosition;
                        deleteMarker _M;
                    }];
                };

                _TRGT = createTrigger ["EmptyDetector", [0,0,0]];
                _TRGT setTriggerArea [1,1,0,false,1];
                _TRGT setTriggerActivation ["NONE", "PRESENT", false];
                _TRGT setTriggerStatements [
                    "!alive V0 && !alive V1 && !alive V2 && !alive V3 && !alive V4 && !alive V5 && !alive V6",
                    " [100] call FLO_fnc_addReward; [100, 'STR_FLO_SUPPORTCONVOY'] call FLO_fnc_sendRewardNotification; ConVLocc = 0; ",
                    ""
                ];

                _INTSTF = ["FlashDisk","FilesSecret","SmartPhone","DocumentsSecret"];
                _INTENMALL = units CGM;
                _INTENMCNT = count _INTENMALL;
                _INTENMCNTNEW = round (_INTENMCNT / 2);
                _INTENMALLNEW = _INTENMALL call BIS_fnc_arrayShuffle;
                _INTENMSEL = _INTENMALLNEW select [0, _INTENMCNTNEW];
                { _x addItem selectRandom _INTSTF } forEach _INTENMSEL;
            };
        };
    };
};
