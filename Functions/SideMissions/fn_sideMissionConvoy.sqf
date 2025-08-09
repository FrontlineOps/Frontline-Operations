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

                private _AGGRSCORE = FLO_DifficultyHandle get "value";

                // Determine destination (front line) objective near players and a far-away start objective
                private _startPos = objNull;
                private _endPos = objNull;
                private _convoyVehicles = [];
                private _markers = [];

                if (!isNil "FLO_Objectives" && {count (keys FLO_Objectives) > 0}) then {
                    private _players = allPlayers;
                    private _frontlineMaxDist = 4000; // near players
                    private _minStartDist = 6000;     // far from frontline

                    // Choose frontline objective near players
                    // Destination objective near players (frontline)
                    private _destObjId = [_frontlineMaxDist, if (count _players > 0) then { getPos (selectRandom _players) } else { [worldSize/2, worldSize/2, 0] }] call FLO_fnc_getObjectiveNearPlayer;

                    private _destData = FLO_Objectives get _destObjId;
                    private _destPosCenter = if (!isNil "_destData") then { _destData get "position" } else { [worldSize/2, worldSize/2, 0] };

                    // Choose start objective far away from destination
                    private _startCandidates = (keys FLO_Objectives) select {
                        _x != _destObjId && {
                            private _p = (FLO_Objectives get _x) get "position";
                            (_p distance2D _destPosCenter) >= _minStartDist
                        }
                    };
                    private _startObjId = if (count _startCandidates > 0) then {
                        // pick the farthest
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

                    // Pick concrete positions within objectives
                    _startPos = [_startObjId] call FLO_fnc_getRandomObjectivePos;
                    _endPos = [_destObjId] call FLO_fnc_getRandomObjectivePos;
                } else {
                    // Fallback if objectives are not available
                    _startPos = player getPos [1500 + random 1000, random 360];
                    _endPos = _startPos getPos [2000 + random 1000, random 360];
                }

                // Create convoy markers
                {
                    private _markerName = _x;
                    private _pos = if (_x == "ConvoyStrt") then {_startPos} else {_endPos};
                    private _text = if (_x == "ConvoyStrt") then {"Convoy Start"} else {"Convoy End"};
                    
                    private _mrkr = createMarker [_markerName, _pos];
                    _mrkr setMarkerType "mil_marker_noShadow";
                    _mrkr setMarkerColor "colorOPFOR";
                    _mrkr setMarkerText _text;
                    _mrkr setMarkerSize [1.5, 1.5];
                    _mrkr setMarkerAlpha 0.7;
                    _markers pushBack _mrkr;
                } forEach ["ConvoyStrt", "ConvoyDest"];

                // Send notifications
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY3", "warning"] call FLO_fnc_sendNotification;
                sleep 600;
                ["STR_FLO_WARNING_TITLE", "STR_FLO_WARNING_ECONVOY4", "warning"] call FLO_fnc_sendNotification;

                ConVLocc = 1;
                private _CNV = selectRandom (_startPos nearRoads 200);
                trg1 = 0;

                // Function to create convoy vehicle
                private _fnc_createConvoyVehicle = {
                    params ["_vehicleType", "_position", "_group"];
                    
                    private _nearRoad = selectRandom (getpos _CNV nearRoads 200);
                    private _vehicle = createVehicle [_vehicleType, _nearRoad getRelPos [0,0], [], 10, "NONE"];
                    _vehicle setDir (getMarkerPos "ConvoyStrt" getDir getMarkerPos "ConvoyDest");
                    _vehicle setUnloadInCombat [true, false];
                    
                    private _crewCount = [typeOf _vehicle, true] call BIS_fnc_crewCount;
                    private _crewGroup = [getPosATL _nearRoad, east, _crewCount] call BIS_fnc_spawnGroup;
                    { _x moveInAny _vehicle } forEach units _crewGroup;
                    { [_x] join _group } forEach units _crewGroup;
                    
                    _convoyVehicles pushBack _vehicle;
                    _vehicle
                };

                // Create main convoy group
                private _mainGroup = [getPosATL _CNV, east, 0] call BIS_fnc_spawnGroup;
                missionNamespace setVariable ["CGM", _mainGroup, true];

                // Create initial vehicles
                private _v0 = [selectRandom East_Ground_Vehicles_Light, _startPos, _mainGroup] call _fnc_createConvoyVehicle;
                waitUntil {((getMarkerPos "ConvoyStrt") distance (getPos _v0)) > 600};
                
                private _v1 = [selectRandom East_Ground_Transport, _startPos, _mainGroup] call _fnc_createConvoyVehicle;
                private _v2 = [selectRandom East_Ground_Vehicles_Light, _startPos, _mainGroup] call _fnc_createConvoyVehicle;

                // Add additional vehicles based on difficulty
                if (_AGGRSCORE > 5) then {
                    private _v3 = [selectRandom East_Ground_Transport, _startPos, _mainGroup] call _fnc_createConvoyVehicle;
                    private _v4 = [selectRandom East_Ground_Vehicles_Light, _startPos, _mainGroup] call _fnc_createConvoyVehicle;
                };

                if (_AGGRSCORE > 10) then {
                    private _v5 = [selectRandom East_Ground_Transport, _startPos, _mainGroup] call _fnc_createConvoyVehicle;
                    private _v6 = [selectRandom East_Ground_Vehicles_Light, _startPos, _mainGroup] call _fnc_createConvoyVehicle;
                };

                // Add event handlers for vehicles and crew
                {
                    _x addEventHandler ["Killed", {
                        params ["_unit"];
                        private _vehicle = nearestObjects [_unit, ["LandVehicle"], 100] select 0;
                        ConVLocc = 0.5;
                        {
                            _x removeAllEventHandlers "Killed";
                            [_x] orderGetIn false;
                            [_x] allowGetIn false;
                            unassignVehicle _x;
                            doGetOut _x;
                            _x allowDamage true;
                        } forEach units group ((crew _vehicle) select 0);
                        [50] call FLO_fnc_addReward;
                        {deleteMarker _x} forEach ["ConvoyStrt", "ConvoyDest"];
                        [50, "STR_FLO_SUPPORTCONVOY"] call FLO_fnc_sendRewardNotification;
                    }];
                } forEach units _mainGroup;

                // Create markers for vehicles
                {
                    if (alive _x) then {
                        private _mrkr = createMarker [str getPos _x, getPos _x];
                        _mrkr setMarkerType "mil_marker_noShadow";
                        _mrkr setMarkerText "DESTROY";
                        _mrkr setMarkerColor "colorOPFOR";
                        _mrkr setMarkerSize [0.9, 0.9];
                        _mrkr setMarkerAlpha 0.7;
                        _markers pushBack _mrkr;
                        
                        _x addEventHandler ["Killed", {
                            params ["_vehicle"];
                            private _markers = allMapMarkers select {markerType _x == "mil_marker_noShadow" && markerAlpha _x == 0.7};
                            private _marker = [_markers, _vehicle] call BIS_fnc_nearestPosition;
                            deleteMarker _marker;
                        }];
                    };
                } forEach _convoyVehicles;

                // Create completion trigger
                private _TRGT = createTrigger ["EmptyDetector", [0,0,0]];
                _TRGT setTriggerArea [1,1,0,false,1];
                _TRGT setTriggerActivation ["NONE", "PRESENT", false];
                _TRGT setTriggerStatements [
                    format ["%1", {!alive _x} count _convoyVehicles == count _convoyVehicles],
                    "[100] call FLO_fnc_addReward; [100, 'STR_FLO_SUPPORTCONVOY'] call FLO_fnc_sendRewardNotification; ConVLocc = 0;",
                    ""
                ];

                // Add intel items to random units
                private _intelItems = ["FlashDisk","FilesSecret","SmartPhone","DocumentsSecret"];
                private _units = units _mainGroup;
                private _selectedUnits = (_units call BIS_fnc_arrayShuffle) select [0, round(count _units / 2)];
                { _x addItem selectRandom _intelItems } forEach _selectedUnits;
            };
        };
    };
};
