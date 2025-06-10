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

        private _markerName = format ["InvesMark_%1", floor diag_tickTime];
        private _mrkr = createMarker [_markerName, (getPos _HQB)];
        _mrkr setMarkerType "mil_warning";
        _mrkr setMarkerColor "colorOPFOR";
        _mrkr setMarkerSize [0.8, 0.8];

        missionNamespace setVariable ["FLO_fnc_inlineSquad", {
            params ["_thisSquadTrigger"];
        }];
private _thisSquadTrigger = _this select 0;
private _AGGRSCORE = FLO_DifficultyHandle get "value";  
private _markerTypes = ["b_installation", "o_installation", "n_installation", "o_support", "n_support", "loc_Power", "loc_Ruin"];
private _allMarks = allMapMarkers select {markerType _x in _markerTypes};

// Pre-allocate array with estimated size to avoid resizing
private _NOSHs = [];
_NOSHs resize (count _allMarks * 5);

// Batch process marker positions
private _markerPositions = _allMarks apply {getMarkerPos _x};
{
    private _nearHouses = nearestObjects [_x, ["HOUSE"], 400];
    _NOSHs append _nearHouses;
} forEach _markerPositions;

// Find suitable HQ building
private _SHs = nearestObjects [_thisSquadTrigger, ["HOUSE"], 7000] select {count (_x buildingPos -1) > 2};
private _HQB = (_SHs - _NOSHs) select 0;

// Cache building positions
private _buildingPositions = _HQB buildingPos -1;

// Spawn intel and initial garrison
["Intel_MIS_01", selectRandom _buildingPositions, [0,0,0], _dir, false, false, true] call LARs_fnc_spawnComp;

// Spawn garrison units with optimized group creation
private _garrisonGroups = [];
for "_i" from 1 to 4 do {
    private _group = [selectRandom _buildingPositions, East, [selectRandom East_Units]] call BIS_fnc_spawnGroup;
    if (_i <= 2) then {
        (units _group select 0) disableAI "PATH";
    };
    _garrisonGroups pushBack _group;
};

// Spawn patrol group
private _patrolGroup = [getPos _HQB, East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[_patrolGroup, getPos _HQB, 200] call BIS_fnc_taskPatrol;

// Spawn guards based on difficulty
private _guardCount = 2 + (_AGGRSCORE > 5) + (_AGGRSCORE > 10);
for "_i" from 1 to _guardCount do {
    private _pos = _HQB getPos [20 + random 200, random 360];
    [East, [selectRandom East_Units], _pos] call BIS_fnc_spawnGroup;
};

// Spawn additional patrols based on difficulty
private _patrolPos = _HQB getPos [100 + random 700, random 360];
private _patrolGroup2 = [East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units], _patrolPos] call BIS_fnc_spawnGroup;
[_patrolGroup2, getPos _HQB, 500] call BIS_fnc_taskPatrol;

if (_AGGRSCORE > 10) then {
    private _patrolPos2 = _HQB getPos [100 + random 700, random 360];
    private _patrolGroup3 = [East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units], _patrolPos2] call BIS_fnc_spawnGroup;
    [_patrolGroup3, getPos _HQB, 1000] call BIS_fnc_taskPatrol;
};

sleep 2;
}];
        private _trgA = createTrigger ["EmptyDetector", (getPos _HQB)];
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

        sleep 1;
        private _attackingAtGrid = mapGridPosition getMarkerPos _mrkr;
        ["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_MIL", _attackingAtGrid], "info"] call FLO_fnc_sendNotification;
    };
};
