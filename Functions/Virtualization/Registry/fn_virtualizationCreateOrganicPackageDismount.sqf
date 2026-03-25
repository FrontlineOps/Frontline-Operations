/*
 * Function: FLO_fnc_virtualizationCreateOrganicPackageDismount
 */

params [
    "_carrierGroupId",
    "_carrierData",
    ["_attachPassengers", true, [true]],
    ["_dismountTargetPos", [], [[]]]
];

private _groupType = _carrierData get "groupType";
private _dismountCount = [_carrierData] call FLO_fnc_virtualizationGetOrganicPackageInfantryCount;
if (_dismountCount <= 0) exitWith { "" };

if ((_carrierData get "organicPackageRole") != "") exitWith { "" };

private _position = _carrierData get "position";
private _homeObjective = _carrierData get "homeObjective";
private _side = _carrierData get "side";

private _dismountGroupId = [_position, "infantry", nil, _homeObjective, _dismountCount, _side] call FLO_fnc_createVirtualGroup;
private _groups = FLO_virtualGroups get "_groups";
private _dismountData = _groups get _dismountGroupId;

_carrierData set ["organicPackageRole", "carrier"];
_carrierData set ["organicPackageParentGroupId", ""];
_dismountData set ["organicPackageRole", "dismount"];
_dismountData set ["organicPackageParentGroupId", _carrierGroupId];

if (_attachPassengers) then {
    [_dismountData, "ORGANIC_PACKAGE", _groupType] call FLO_fnc_virtualizationSetMissionLock;

    if !([_dismountGroupId, _carrierGroupId] call FLO_fnc_transportAttach) then {
        throw format [
            "FLO_fnc_virtualizationCreateOrganicPackageDismount: failed to attach organic dismount %1 to %2",
            _dismountGroupId,
            _carrierGroupId
        ];
    };

    if (count _dismountTargetPos >= 2) then {
        _carrierData set ["dismountAtWaypoint", 0];
        _dismountData set ["postDismountWaypoint", [_dismountTargetPos, "ORGANIC_PACKAGE"]];
    };
};

["VIRTUALIZATION", 3, format [
    "Created organic %1 dismount %2 (%3 infantry) for %4",
    _groupType,
    _dismountGroupId,
    _dismountCount,
    _carrierGroupId
]] call FLO_fnc_log;

_dismountGroupId
