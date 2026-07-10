/*
 * Function: FLO_fnc_virtualizationCreateOrganicPackageDismount
 */

params [
    "_carrierGroupId",
    ["_attachPassengers", true, [true]],
    ["_dismountTargetPos", [], [[]]]
];

private _carrierData = [_carrierGroupId] call FLO_fnc_virtualizationRequireGroup;
private _groupType = _carrierData get "groupType";
private _dismountCounts = [_carrierData] call FLO_fnc_virtualizationGetOrganicPackageInfantryCounts;
if (_dismountCounts isEqualTo []) exitWith { [] };

if ((_carrierData get "organicPackageRole") != "") exitWith { [] };

private _position = _carrierData get "position";
private _homeObjective = _carrierData get "homeObjective";
private _side = _carrierData get "side";

private _previousRole = _carrierData get "organicPackageRole";
private _previousParentGroupId = _carrierData get "organicPackageParentGroupId";
private _createdGroupIds = [];
private _totalInfantry = 0;

[_carrierGroupId, createHashMapFromArray [
    ["organicPackageRole", "carrier"],
    ["organicPackageParentGroupId", ""]
]] call FLO_fnc_virtualizationPatchGroup;

{
    private _dismountCount = _x;
    private _dismountGroupId = [_position, "infantry", nil, _homeObjective, _dismountCount, _side] call FLO_fnc_createVirtualGroup;
    if (_dismountGroupId == "") then {
        [_carrierGroupId, _createdGroupIds, _previousRole, _previousParentGroupId] call FLO_fnc_virtualizationRollbackOrganicPackageCreation;
        throw format [
            "FLO_fnc_virtualizationCreateOrganicPackageDismount: failed to create organic dismount package %1 for %2 due to invalid carrier position %3",
            _forEachIndex,
            _carrierGroupId,
            _position
        ];
    };

    private _dismountChanges = createHashMapFromArray [
        ["organicPackageRole", "dismount"],
        ["organicPackageParentGroupId", _carrierGroupId]
    ];

    if (_attachPassengers) then {
        _dismountChanges set ["missionLock", "ORGANIC_PACKAGE"];
        _dismountChanges set ["missionType", _groupType];
        if (count _dismountTargetPos >= 2) then {
            _dismountChanges set ["postDismountWaypoint", [_dismountTargetPos, "ORGANIC_PACKAGE"]];
        };
    };
    [_dismountGroupId, _dismountChanges] call FLO_fnc_virtualizationPatchGroup;

    if (_attachPassengers) then {
        if !([_dismountGroupId, _carrierGroupId] call FLO_fnc_transportAttach) then {
            [_carrierGroupId, _createdGroupIds + [_dismountGroupId], _previousRole, _previousParentGroupId] call FLO_fnc_virtualizationRollbackOrganicPackageCreation;
            throw format [
                "FLO_fnc_virtualizationCreateOrganicPackageDismount: failed to attach organic dismount %1 to %2",
                _dismountGroupId,
                _carrierGroupId
            ];
        };

    };

    _createdGroupIds pushBack _dismountGroupId;
    _totalInfantry = _totalInfantry + _dismountCount;
} forEach _dismountCounts;

if (_attachPassengers && {count _dismountTargetPos >= 2}) then {
    [_carrierGroupId, createHashMapFromArray [["dismountAtWaypoint", 0]]] call FLO_fnc_virtualizationPatchGroup;
};

["VIRTUALIZATION", 3, format [
    "Created %1 organic %2 dismount groups (%3 infantry total) for %4",
    count _createdGroupIds,
    _groupType,
    _totalInfantry,
    _carrierGroupId
]] call FLO_fnc_log;

_createdGroupIds
