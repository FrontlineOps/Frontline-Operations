/*
 * Function: FLO_fnc_transportProcessVirtualCarrier
 * Author: Frontline Operations Development Group
 * Description:
 *   Handles purely virtual carrier-specific logic while the group is moving in
 *   the virtual world, including early threat-triggered unload and stale
 *   dismount-state cleanup.
 *
 * Arguments:
 *   0: Carrier Group ID <STRING>
 *   1: Carrier Group Data <HASHMAP>
 *   2: Carrier Position <ARRAY>
 *
 * Return Value:
 *   BOOL - True when transport-specific handling ran
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_carrierPos", [0, 0, 0], [[]]]
];

if (_groupId == "") exitWith { false };
if !([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) exitWith { false };

private _attachedIds = +([_groupData] call FLO_fnc_virtualizationGetTransportPassengers);
if (count _attachedIds == 0) exitWith {
    if ((_groupData get "dismountAtWaypoint") >= 0 || {(_groupData get "transportInsertMode") != ""}) then {
        ["TRANSPORT", 2, format [
            "Virtual carrier %1 had stale dismount state with no attached passengers - clearing",
            _groupId
        ]] call FLO_fnc_log;
        [_groupData] call FLO_fnc_transportClearInsertState;
    };
    false
};

if ((_groupData get "dismountAtWaypoint") < 0) exitWith { false };

if !([_groupData, _carrierPos] call FLO_fnc_transportShouldThreatDismount) exitWith { false };

["TRANSPORT", 3, format [
    "Virtual carrier %1 encountered threat conditions - unloading passengers early",
    _groupId
]] call FLO_fnc_log;

[_groupId, true] call FLO_fnc_transportDismount;

true
