/*
 * Function: FLO_fnc_gtnLogStrategicOrderPerf
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Emits thresholded sub-phase timings for one strategic ATTACK, DEFEND,
 *   or GARRISON order. The log is observational only and is used to split
 *   route/path updates from state assignment and transport reassignment.
 *
 * Arguments:
 * 0: GTN commander <HASHMAP>
 * 1: Order type <STRING>
 * 2: Group id <STRING>
 * 3: Group type <STRING>
 * 4: Objective id <STRING>
 * 5: Route update time in ms <NUMBER>
 * 6: State assignment time in ms <NUMBER>
 * 7: Transport request time in ms <NUMBER>
 * 8: Total order time in ms <NUMBER>
 *
 * Return Value:
 * Logged <BOOL>
 */

params [
    ["_commander", nil],
    ["_orderType", "", [""]],
    ["_groupId", "", [""]],
    ["_groupType", "", [""]],
    ["_objectiveId", "", [""]],
    ["_routeMs", 0, [0]],
    ["_assignMs", 0, [0]],
    ["_transportMs", 0, [0]],
    ["_totalMs", 0, [0]]
];

if (isNil "_commander") exitWith { false };

private _perf = _commander get "_perf";
private _thresholdMs = _perf get "orderLogThresholdMs";
if (_totalMs < _thresholdMs) exitWith { false };

private _objectiveLabel = _objectiveId;
if (_objectiveLabel == "") then {
    _objectiveLabel = "<free>";
};

diag_log format [
    "[FLO][PERF] GTN order %1 %2 group=%3 type=%4 objective=%5 route=%6 assign=%7 transport=%8 total=%9",
    _commander get "_sideKey",
    _orderType,
    _groupId,
    _groupType,
    _objectiveLabel,
    _routeMs,
    _assignMs,
    _transportMs,
    _totalMs
];

true
