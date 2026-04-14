/*
 * Function: FLO_fnc_virtualizationEnsureUpdateState
 */

params [
    ["_batchSize", 25, [0]],
    ["_playerCacheInterval", 1, [0]],
    ["_forceReset", false, [true]]
];

if (isNil "FLO_VirtUpdate" || {_forceReset}) then {
    FLO_VirtUpdate = [_batchSize, _playerCacheInterval] call FLO_fnc_virtualizationCreateUpdateState;
} else {
    if ((FLO_VirtUpdate get "batchSize") != _batchSize) then {
        ["VIRTUALIZATION", 2, format [
            "Correcting stale virtualization batch size %1 -> %2",
            FLO_VirtUpdate get "batchSize",
            _batchSize
        ]] call FLO_fnc_log;
        FLO_VirtUpdate set ["batchSize", _batchSize];
        FLO_VirtUpdate set ["currentBatchIndex", 0];
        FLO_VirtUpdate set ["cachedGroupIds", []];
        FLO_VirtUpdate set ["lastGroupCacheTime", 0];
    };

    if ((FLO_VirtUpdate get "playerCacheInterval") != _playerCacheInterval) then {
        ["VIRTUALIZATION", 2, format [
            "Correcting stale player cache interval %1 -> %2",
            FLO_VirtUpdate get "playerCacheInterval",
            _playerCacheInterval
        ]] call FLO_fnc_log;
        FLO_VirtUpdate set ["playerCacheInterval", _playerCacheInterval];
        FLO_VirtUpdate set ["cachedPlayerPositions", []];
        FLO_VirtUpdate set ["lastPlayerCacheTime", 0];
    };
};

call FLO_fnc_virtualizationValidateUpdateState;

FLO_VirtUpdate
