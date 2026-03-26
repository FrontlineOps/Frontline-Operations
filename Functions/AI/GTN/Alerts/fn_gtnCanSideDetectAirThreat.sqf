/*
 * Function: FLO_fnc_gtnCanSideDetectAirThreat
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether the provided side has a plausible detection path on an
 *   inbound aircraft. Detection can come from local visual observers near the
 *   aircraft or from active radar/air-defense coverage.
 *
 * Arguments:
 *   0: Aircraft object <OBJECT>
 *   1: Target position <ARRAY>
 *   2: Detecting side <SIDE>
 *
 * Return Value:
 *   BOOL
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_detectingSide", sideUnknown]
];

if (isNull _aircraft) exitWith { false };
if !(_detectingSide in [east, west]) exitWith { false };

private _airPos = getPosATL _aircraft;

if ([_airPos, 3000, _detectingSide] call FLO_fnc_gtnCanSideObserveArea) exitWith { true };

private _groups = FLO_virtualGroups get "_groups";
private _radarGroupIds = ["queryRadius", [_airPos, 50000, _detectingSide, true]] call FLO_fnc_virtualizationSpatialIndex;

(_radarGroupIds findIf {
    private _groupData = _groups get _x;
    if ((_groupData get "side") != _detectingSide) exitWith { false };

    private _groupType = _groupData get "groupType";
    if !(_groupType in ["static_aa", "radar", "mobile_aa"]) exitWith { false };

    private _isDetecting = (_groupData get "alwaysActive") || (_groupData get "isActive");
    _isDetecting
}) >= 0
