/*
 * Function: FLO_fnc_gtnSyncAlertBatch
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side batch entrypoint for multiple GTN alert marker sync records.
 *
 * Arguments:
 *   0: Alert records <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_records", [], [[]]]
];

{
    _x params [
        ["_sideKey", "", [""]],
        ["_alertId", "", [""]],
        ["_alertType", "", [""]],
        ["_position", [0, 0, 0], [[]], [3]],
        ["_radius", 0, [0]],
        ["_duration", 60, [0]],
        ["_payload", [], [[]]]
    ];

    [_sideKey, _alertId, _alertType, _position, _radius, _duration, _payload] call FLO_fnc_gtnSyncAlertMarkers;
} forEach _records;

true
