/* Collects exact maintained ground contacts for one CAS objective. */
params [
    ["_requestSide", sideUnknown],
    ["_objectiveId", "", [""]]
];

if !(_requestSide in [east, west]) then { throw "CAS target collection requires EAST or WEST"; };
private _objective = FLO_Objectives get _objectiveId;
private _targetPos = _objective get "position";
private _enemySide = [east, west] select (_requestSide isEqualTo east);
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _nearIds = ["queryRadius", [_targetPos, 1000, _enemySide, true]] call FLO_fnc_virtualizationSpatialIndex;
private _targets = [];

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if ((_groupData get "unitCount") <= 0) then { continue };
    if (([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) != "") then { continue };
    if !((_groupData get "groupType") in ["infantry", "motorized", "mechanized", "armor", "mobile_aa", "artillery", "static_aa"]) then { continue };
    _targets pushBack [(_groupData get "position") distance2D _targetPos, _groupId];
} forEach _nearIds;

_targets sort true;
_targets apply { _x select 1 }
