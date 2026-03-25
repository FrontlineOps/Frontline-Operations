/*
 * Function: FLO_fnc_gtnAlertIncomingAircraft
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a reported hostile air contact warning to the side being
 *   targeted. Detection gating happens before this function is called.
 *
 * Arguments:
 *   0: Target position <ARRAY>
 *   1: Mission type <STRING>
 *   2: Target side <SIDE>
 *
 * Return Value:
 *   HASHMAP - Published alert data
 */

params [
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_missionType", "CAS", [""]],
    ["_targetSide", sideUnknown]
];

if !(_targetSide in [east, west]) exitWith { createHashMap };

private _radius = switch (toUpper _missionType) do {
    case "CAP": { 1800 };
    case "RECON": { 1200 };
    default { 1000 };
};

private _grid = mapGridPosition _targetPos;
private _message = format ["HOSTILE AIR CONTACT reported near grid %1", _grid];

[_targetSide, "AIR_INCOMING", _targetPos, _radius, 75, _message] call FLO_fnc_gtnPublishAlert
