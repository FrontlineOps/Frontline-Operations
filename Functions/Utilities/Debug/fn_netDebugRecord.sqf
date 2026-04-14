/*
 * Function: FLO_fnc_netDebugRecord
 * Author: Frontline Operations Development Group
 * Description:
 *   Aggregates lightweight network-related counters into a rolling server-side
 *   debug window and emits a summarized dump on interval.
 *
 * Arguments:
 *   0: Counter key <STRING>
 *   1: Increment amount <NUMBER>
 *
 * Return Value:
 *   BOOL
 */

if (!isServer) exitWith { false };

params [
    ["_counterKey", "", [""]],
    ["_amount", 1, [0]]
];

if (_counterKey == "") exitWith { false };

if (isNil "FLO_NetDebugEnabled") then {
    FLO_NetDebugEnabled = true;
};
if (!FLO_NetDebugEnabled) exitWith { false };

if (isNil "FLO_NetDebugState") then {
    FLO_NetDebugState = createHashMapFromArray [
        ["windowStartedAt", diag_tickTime],
        ["windowSeconds", 60],
        ["counters", createHashMap]
    ];
};

private _state = FLO_NetDebugState;
private _windowStartedAt = _state get "windowStartedAt";
private _windowSeconds = _state get "windowSeconds";

if ((diag_tickTime - _windowStartedAt) >= _windowSeconds) then {
    [] call FLO_fnc_netDebugDump;
    _state = FLO_NetDebugState;
};

private _counters = _state get "counters";
private _current = if (_counterKey in _counters) then { _counters get _counterKey } else { 0 };
_counters set [_counterKey, _current + _amount];

true
