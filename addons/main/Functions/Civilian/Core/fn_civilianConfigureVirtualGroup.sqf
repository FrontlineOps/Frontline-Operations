/*
 * Function: FLO_fnc_civilianConfigureVirtualGroup
 * Description:
 *   Applies one civilian domain profile through the virtual-force registry.
 */

params [
    ["_groupId", "", [""]],
    ["_profile", createHashMap, [createHashMap]],
    ["_objectiveId", "", [""]],
    ["_anchorPos", [], [[]]],
    ["_direction", -1, [0]]
];

if (_groupId == "" || {_objectiveId == ""} || {count _anchorPos < 2}) then {
    throw format [
        "FLO_fnc_civilianConfigureVirtualGroup: invalid identity or anchor group=%1 objective=%2 pos=%3",
        _groupId,
        _objectiveId,
        _anchorPos
    ];
};

private _changes = createHashMapFromArray [
    ["civilianRole", _profile get "role"],
    ["civilianObjective", _objectiveId],
    ["civilianAnchorPos", +_anchorPos],
    ["civilianHomeAnchorPos", +_anchorPos],
    ["civilianRoutineAnchorPos", +_anchorPos],
    ["civilianRouteAnchors", [+_anchorPos]],
    ["civilianKnowledgeBias", _profile get "knowledgeBias"],
    ["civilianTrustBias", _profile get "trustBias"],
    ["civilianRoutineState", _profile get "routineState"],
    ["civilianLastMood", "NEUTRAL"]
];
if (_direction >= 0) then {
    _changes set ["direction", _direction];
};

[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup
