/*
 * Function: FLO_fnc_virtualizationBuildGroupData
 */

params [
    ["_position", [0,0,0], [[]]],
    ["_groupType", "infantry", [""]],
    ["_groupCfg", configNull, [configNull, []]],
    ["_homeObjective", "", [""]],
    ["_unitCount", -1, [0]],
    ["_side", east, [east]],
    ["_spawnClass", "", [""]],
    ["_groupId", "", [""]]
];

if (_groupId == "") then {
    throw "FLO_fnc_virtualizationBuildGroupData: empty group id";
};

_position = [_position] call FLO_fnc_virtualizationNormalizePosition;
private _archetype = [_groupType] call FLO_fnc_virtualizationGetArchetype;

private _resolvedUnitCount = _unitCount;
if (_resolvedUnitCount < 0) then {
    switch (_archetype get "countMode") do {
        case "RANDOM_CIV": { _resolvedUnitCount = 1 + floor random 3; };
        case "FIXED_ONE": { _resolvedUnitCount = 1; };
        case "FACTION": { _resolvedUnitCount = [_groupType, _side] call FLO_fnc_getGroupTypeCount; };
        default {
            throw format ["Unsupported count mode for virtual-group archetype %1", _groupType];
        };
    };
};

private _groupData = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
_groupData set ["id", _groupId];
_groupData set ["position", +_position];
_groupData set ["spawnPosition", +_position];
_groupData set ["groupType", _groupType];
_groupData set ["groupCfg", _groupCfg];
_groupData set ["spawnClass", _spawnClass];
_groupData set ["homeObjective", _homeObjective];
_groupData set ["unitCount", _resolvedUnitCount];
_groupData set ["side", _side];
_groupData set ["garrisonPosition", +_position];
_groupData set ["civilianObjective", _homeObjective];
_groupData set ["civilianAnchorPos", +_position];
_groupData set ["civilianHomeAnchorPos", +_position];
_groupData set ["civilianRoutineAnchorPos", +_position];

private _initialAssetComposition = [_groupType, _resolvedUnitCount, _side] call FLO_fnc_virtualizationSelectInitialAssetComposition;
if (_initialAssetComposition isNotEqualTo []) then {
    [_groupData, _initialAssetComposition] call FLO_fnc_virtualizationSetAssetComposition;
};

_groupData
