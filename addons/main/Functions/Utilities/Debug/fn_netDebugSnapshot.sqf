/*
 * Function: FLO_fnc_netDebugSnapshot
 * Author: Frontline Operations Development Group
 * Description:
 *   Captures current aggregated network counters together with live mission
 *   world counts for debugging desync and broadcast pressure.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Snapshot <HASHMAP>
 */

private _counters = createHashMap;
private _windowStartedAt = -1;
private _windowSeconds = 60;

if (!isNil "FLO_NetDebugState") then {
    _windowStartedAt = FLO_NetDebugState get "windowStartedAt";
    _windowSeconds = FLO_NetDebugState get "windowSeconds";
    {
        _counters set [_x, (FLO_NetDebugState get "counters") get _x];
    } forEach (keys (FLO_NetDebugState get "counters"));
};

private _virtualGroupCount = 0;
if (!isNil "FLO_VirtualForceRegistry") then {
    private _groups = call FLO_fnc_virtualizationGetGroupMap;
    _virtualGroupCount = count (keys _groups);
};

createHashMapFromArray [
    ["windowStartedAt", _windowStartedAt],
    ["windowSeconds", _windowSeconds],
    ["windowAgeSeconds", if (_windowStartedAt >= 0) then { diag_tickTime - _windowStartedAt } else { -1 }],
    ["serverFps", diag_fps],
    ["players", count ([false] call FLO_fnc_getConnectedHumanPlayers)],
    ["aiUnits", { !isPlayer _x } count allUnits],
    ["groups", count allGroups],
    ["vehicles", count vehicles],
    ["deadMen", count allDeadMen],
    ["deadAll", count allDead],
    ["markers", count allMapMarkers],
    ["virtualGroups", _virtualGroupCount],
    ["counters", _counters]
]
