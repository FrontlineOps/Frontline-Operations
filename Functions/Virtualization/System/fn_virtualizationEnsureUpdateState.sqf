/*
 * Function: FLO_fnc_virtualizationEnsureUpdateState
 */

params [
    ["_batchSize", 25, [0]],
    ["_playerCacheInterval", 1, [0]]
];

if (isNil "FLO_VirtUpdate") then {
    FLO_VirtUpdate = [_batchSize, _playerCacheInterval] call FLO_fnc_virtualizationCreateUpdateState;
};

call FLO_fnc_virtualizationValidateUpdateState;

FLO_VirtUpdate
