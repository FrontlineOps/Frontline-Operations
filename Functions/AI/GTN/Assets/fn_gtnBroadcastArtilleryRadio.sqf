/*
 * Function: FLO_fnc_gtnBroadcastArtilleryRadio
 * Author: Frontline Operations Development Group
 * Description:
 *   Broadcasts a short own-side artillery radio sequence for a fire mission.
 *
 * Arguments:
 *   0: Request side <SIDE>
 *   1: Target position <ARRAY>
 *   2: Rounds <NUMBER>
 *   3: ETA min <NUMBER>
 *   4: ETA max <NUMBER>
 *   5: Request kind <STRING>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_requestSide", sideUnknown],
    ["_targetPos", [0, 0, 0], [[]], 3],
    ["_rounds", 0, [0]],
    ["_etaMin", -1, [0]],
    ["_etaMax", -1, [0]],
    ["_requestKind", "GENERAL", [""]]
];

if !(_requestSide in [east, west]) exitWith { false };

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

[_requestSide, "HQ", _requestText, 0] remoteExecCall ["FLO_fnc_gtnCommanderRadioMessage", 0, false];
[_requestSide, "ARTY", _ackText, 1.5] remoteExecCall ["FLO_fnc_gtnCommanderRadioMessage", 0, false];
[_requestSide, "ARTY", _shotText, 4] remoteExecCall ["FLO_fnc_gtnCommanderRadioMessage", 0, false];

true
