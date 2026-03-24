/*
 * Function: FLO_fnc_virtualizationSyncRealGroupOutcome
 */

params ["_groupId", "_groupData", "_realGroup"];

private _groupType = _groupData get "groupType";
private _aliveUnits = units _realGroup select { alive _x };
private _aliveUnitCount = count _aliveUnits;
private _tracksAssets = [_groupType] call FLO_fnc_virtualizationUsesAssetStrength;
private _assetVehicles = [_groupData, _realGroup] call FLO_fnc_virtualizationGetRealAssetVehicles;
private _syncedCount = if (_tracksAssets) then {
    count _assetVehicles
} else {
    _aliveUnitCount
};

private _syncedComp = if (_tracksAssets) then {
    _assetVehicles apply { typeOf _x }
} else {
    _aliveUnits apply { typeOf _x }
};

_groupData set ["unitCount", _syncedCount];
_groupData set ["comp", _syncedComp];

["VIRTUALIZATION", 4, format ["Synced unitCount for %1 (%2): %3", _groupId, _groupType, _syncedCount]] call FLO_fnc_log;
["VIRTUALIZATION", 4, format ["Synced comp for %1 (%2): %3 entries", _groupId, _groupType, count _syncedComp]] call FLO_fnc_log;

[_tracksAssets, _syncedCount]
