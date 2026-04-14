/*
 * Function: FLO_fnc_gtnPublishAlert
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a temporary GTN alert to one side as both a notification and
 *   local alert markers. Alerts are transient and separate from the commander
 *   COP marker picture.
 *
 * Arguments:
 *   0: Target side <SIDE>
 *   1: Alert type <STRING>
 *   2: Position <ARRAY>
 *   3: Radius <NUMBER>
 *   4: Duration seconds <NUMBER>
 *   5: Notification text <STRING>
 *   6: Alert payload <ARRAY>
 *
 * Return Value:
 *   HASHMAP - Published alert data
 */

params [
    ["_targetSide", sideUnknown],
    ["_alertType", "", [""]],
    ["_position", [0, 0, 0], [[]], [3]],
    ["_radius", 0, [0]],
    ["_duration", 60, [0]],
    ["_message", "", [""]],
    ["_payload", [], [[]]]
];

if (!isServer) exitWith { createHashMap };
if !(_targetSide in [east, west]) exitWith { createHashMap };
if ((count _position) < 2) exitWith { createHashMap };

if (_duration < 10) then { _duration = 10; };
if (_radius < 0) then { _radius = 0; };

if (isNil "FLO_GTN_AlertSequence") then {
    FLO_GTN_AlertSequence = 0;
};
FLO_GTN_AlertSequence = FLO_GTN_AlertSequence + 1;

private _sideKey = ([_targetSide] call FLO_fnc_gtnSideContext) get "sideKey";
private _alertId = format ["FLO_GTN_ALERT_%1_%2", _sideKey, FLO_GTN_AlertSequence];

if (_message != "") then {
    [_message, "warning", false, _targetSide] call FLO_fnc_sendNotification;
};

if (isNil "FLO_GTN_PendingAlertPublishes") then {
    FLO_GTN_PendingAlertPublishes = createHashMapFromArray [
        ["EAST", []],
        ["WEST", []]
    ];
};
if (isNil "FLO_GTN_AlertBatchScheduled") then {
    FLO_GTN_AlertBatchScheduled = createHashMapFromArray [
        ["EAST", false],
        ["WEST", false]
    ];
};

(FLO_GTN_PendingAlertPublishes get _sideKey) pushBack [
    _sideKey,
    _alertId,
    _alertType,
    _position,
    _radius,
    _duration,
    _payload
];

if !(FLO_GTN_AlertBatchScheduled get _sideKey) then {
    FLO_GTN_AlertBatchScheduled set [_sideKey, true];
    [{
        params ["_queuedSideKey"];
        [_queuedSideKey] call FLO_fnc_gtnFlushAlertQueue;
    }, [_sideKey], 0.25] call CBA_fnc_waitAndExecute;
};

createHashMapFromArray [
    ["id", _alertId],
    ["sideKey", _sideKey],
    ["type", _alertType],
    ["position", _position],
    ["radius", _radius],
    ["duration", _duration],
    ["message", _message],
    ["payload", _payload]
]
