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
private _dismountCounts = [_carrierData] call FLO_fnc_virtualizationGetOrganicPackageInfantryCounts;
if (count _dismountCounts == 0) exitWith { [] };

if ((_carrierData get "organicPackageRole") != "") exitWith { [] };

private _position = _carrierData get "position";
private _homeObjective = _carrierData get "homeObjective";
private _side = _carrierData get "side";

private _groups = FLO_virtualGroups get "_groups";
private _previousRole = _carrierData get "organicPackageRole";
private _previousParentGroupId = _carrierData get "organicPackageParentGroupId";
private _createdGroupIds = [];
private _totalInfantry = 0;

_carrierData set ["organicPackageRole", "carrier"];
_carrierData set ["organicPackageParentGroupId", ""];

{
    private _dismountCount = _x;
    private _dismountGroupId = [_position, "infantry", nil, _homeObjective, _dismountCount, _side] call FLO_fnc_createVirtualGroup;
    if (_dismountGroupId == "") then {
        [_carrierData, _createdGroupIds, _previousRole, _previousParentGroupId] call FLO_fnc_virtualizationRollbackOrganicPackageCreation;
        throw format [
            "FLO_fnc_virtualizationCreateOrganicPackageDismount: failed to create organic dismount package %1 for %2 due to invalid carrier position %3",
            _forEachIndex,
            _carrierGroupId,
            _position
        ];
    };

    private _dismountData = _groups get _dismountGroupId;
    _dismountData set ["organicPackageRole", "dismount"];
    _dismountData set ["organicPackageParentGroupId", _carrierGroupId];

    if (_attachPassengers) then {
        [_dismountData, "ORGANIC_PACKAGE", _groupType] call FLO_fnc_virtualizationSetMissionLock;

        if !([_dismountGroupId, _carrierGroupId] call FLO_fnc_transportAttach) then {
            [_carrierData, _createdGroupIds + [_dismountGroupId], _previousRole, _previousParentGroupId] call FLO_fnc_virtualizationRollbackOrganicPackageCreation;
            throw format [
                "FLO_fnc_virtualizationCreateOrganicPackageDismount: failed to attach organic dismount %1 to %2",
                _dismountGroupId,
                _carrierGroupId
            ];
        };

        if (count _dismountTargetPos >= 2) then {
            _dismountData set ["postDismountWaypoint", [_dismountTargetPos, "ORGANIC_PACKAGE"]];
        };
    };

    _createdGroupIds pushBack _dismountGroupId;
    _totalInfantry = _totalInfantry + _dismountCount;
} forEach _dismountCounts;

if (_attachPassengers && {count _dismountTargetPos >= 2}) then {
    _carrierData set ["dismountAtWaypoint", 0];
};

["VIRTUALIZATION", 3, format [
    "Created %1 organic %2 dismount groups (%3 infantry total) for %4",
    count _createdGroupIds,
    _groupType,
    _totalInfantry,
    _carrierGroupId
]] call FLO_fnc_log;

_createdGroupIds
