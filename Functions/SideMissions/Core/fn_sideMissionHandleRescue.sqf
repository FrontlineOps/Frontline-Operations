/*
 * Function: FLO_fnc_sideMissionHandleRescue
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-authoritative rescue progress handler for rescue side missions.
 *   Releases rescued friendlies, removes them from mission cleanup tracking,
 *   and completes the mission immediately once the rescue threshold is met.
 *
 * Arguments:
 *   0: Mission ID (STRING)
 *   1: Rescued unit (OBJECT)
 *
 * Returns:
 *   BOOL - True if handled
 */

params [["_missionId", ""], ["_unit", objNull]];

if (_missionId == "" || {isNull _unit}) exitWith { false };

private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
if (isNil "_instance") exitWith { false };

private _state = ["get", [_missionId]] call FLO_fnc_sideMissionState;
if (_state >= 3) exitWith { true };

if (alive _unit) then {
    _unit setCaptive false;
    _unit enableAI "PATH";
    _unit enableAI "MOVE";
    _unit enableAI "ANIM";
    _unit switchMove "";
};

["removeEntity", [_missionId, _unit]] call FLO_fnc_sideMissionEntityTracker;

private _type = _instance get "type";
private _data = _instance get "data";
private _shouldComplete = false;

switch (_type) do {
    case "pilotRescue": {
        _data set ["pilotRescued", true];
        _shouldComplete = true;
    };

    case "powRescue": {
        private _rescuedUnits = _data get "rescuedUnits";
        _rescuedUnits pushBackUnique _unit;

        private _initialCount = _data get "initialCount";
        _shouldComplete = (count _rescuedUnits) >= ceil (_initialCount / 2);
    };

    case "squadRescue": {
        private _rescuedUnits = _data get "rescuedUnits";
        _rescuedUnits pushBackUnique _unit;

        private _initialCount = _data get "initialCount";
        _shouldComplete = (count _rescuedUnits) >= ceil (_initialCount / 2);
    };
};

if (_shouldComplete) then {
    ["complete", [_missionId, true, "Rescue objective completed"]] call FLO_fnc_sideMissionManager;
};

true
