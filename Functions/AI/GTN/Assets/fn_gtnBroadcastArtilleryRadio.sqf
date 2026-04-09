/*
 * Function: FLO_fnc_gtnBroadcastArtilleryRadio
 * Author: Frontline Operations Development Group
 * Description:
 *   Broadcasts a short own-side artillery radio sequence for a fire mission.
 *
 * Arguments:
 *   0: Request side <SIDE>
 *   1: Mission record <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_requestSide", sideUnknown],
    ["_missionRecord", createHashMap]
];

if !(_requestSide in [east, west]) exitWith { false };
if (count (keys _missionRecord) == 0) exitWith { false };

private _missionId = _missionRecord get "missionId";
private _targetPos = _missionRecord get "targetPos";
private _rounds = _missionRecord get "rounds";
private _etaMin = _missionRecord get "etaMin";
private _etaMax = _missionRecord get "etaMax";
private _requestKind = _missionRecord get "requestKind";
private _grid = mapGridPosition _targetPos;
private _requestText = switch (toUpper _requestKind) do {
    case "COUNTER_BATTERY": { format ["Counter-battery requested, %1 rounds on grid %2.", _rounds, _grid] };
    case "OBSERVED": { format ["Observed target. %1 rounds on grid %2.", _rounds, _grid] };
    default { format ["Artillery requested, %1 rounds on grid %2.", _rounds, _grid] };
};
private _ackText = format ["Grid %1 received. Fire mission acknowledged.", _grid];
private _shotText = if (_etaMax > 0) then {
    if (_etaMin >= 0 && {_etaMax > _etaMin}) then {
        format ["Shot. %1 rounds, ETA %2-%3 seconds, grid %4, confirm.", _rounds, _etaMin, _etaMax, _grid]
    } else {
        format ["Shot. %1 rounds, ETA %2 seconds, grid %3, confirm.", _rounds, _etaMax, _grid]
    }
} else {
    format ["Shot. %1 rounds, grid %2, confirm.", _rounds, _grid]
};

private _sequence = [
    ["HQ", _requestText, 0],
    ["ARTY", _ackText, 1.5],
    ["ARTY", _shotText, 4]
];

private _targetOwners = [_requestSide] call FLO_fnc_gtnGetSideClientOwners;
if (count _targetOwners == 0) exitWith { false };

[_requestSide, _missionId, _sequence] remoteExecCall ["FLO_fnc_gtnQueueArtilleryRadioMission", _targetOwners, false];

["artilleryRadioMissions", 1] call FLO_fnc_netDebugRecord;
["artilleryRadioLines", count _sequence] call FLO_fnc_netDebugRecord;
["artilleryRadioTargets", count _targetOwners] call FLO_fnc_netDebugRecord;

true
