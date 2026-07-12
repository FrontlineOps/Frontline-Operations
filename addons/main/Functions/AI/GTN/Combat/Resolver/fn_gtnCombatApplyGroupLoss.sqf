/* Applies one exact virtual group loss while keeping asset composition aligned. */
params [
    ["_groupId", "", [""]],
    ["_requestedLoss", 0, [0]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if !(_groupId in _groups) exitWith { 0 };

private _groupData = _groups get _groupId;
private _currentCount = _groupData get "unitCount";
private _loss = ((floor _requestedLoss) max 0) min _currentCount;
if (_loss <= 0) exitWith { 0 };

private _newCount = _currentCount - _loss;
if (_newCount <= 0) exitWith {
    if (!isNil "FLO_GTN_VirtualCombatResumeStates") then {
        FLO_GTN_VirtualCombatResumeStates deleteAt _groupId;
    };
    [_groupId] call FLO_fnc_virtualizationRemoveGroup;
    _loss
};

private _changes = createHashMapFromArray [["unitCount", _newCount]];
private _tracksAssets = [(_groupData get "groupType")] call FLO_fnc_virtualizationUsesAssetStrength;
private _composition = +(_groupData get "comp");
if (_tracksAssets && {(count _composition) > _newCount}) then {
    _composition resize _newCount;
    _changes set ["comp", _composition];
};

[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;
_loss
