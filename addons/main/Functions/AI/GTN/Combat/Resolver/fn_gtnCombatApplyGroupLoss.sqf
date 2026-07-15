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

if (_groupData get "isActive") exitWith {
    ["GTN Combat", 2, format [
        "Rejected abstract group loss group=%1 reason=ACTIVE_PHYSICAL",
        _groupId
    ]] call FLO_fnc_log;
    0
};

private _newCount = _currentCount - _loss;
if (_newCount <= 0) exitWith {
    private _catastrophicPassengerLoss = [_groupData] call FLO_fnc_virtualizationIsTransportCarrier;
    private _removed = [_groupId, _catastrophicPassengerLoss] call FLO_fnc_virtualizationRemoveGroup;
    if (_removed && {!isNil "FLO_GTN_VirtualCombatResumeStates"}) then {
        FLO_GTN_VirtualCombatResumeStates deleteAt _groupId;
    };
    [0, _loss] select _removed
};

private _changes = createHashMapFromArray [["unitCount", _newCount]];
private _tracksAssets = [(_groupData get "groupType")] call FLO_fnc_virtualizationUsesAssetStrength;
private _composition = +(_groupData get "comp");
if (_tracksAssets && {(count _composition) > _newCount}) then {
    _composition resize _newCount;
    _changes set ["comp", _composition];
};

if (_groupData get "isActive") exitWith {
    ["GTN Combat", 2, format [
        "Rejected abstract group loss group=%1 reason=ACTIVE_PHYSICAL",
        _groupId
    ]] call FLO_fnc_log;
    0
};

[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;
_loss
