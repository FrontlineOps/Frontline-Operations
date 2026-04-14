/*
 * Function: FLO_fnc_virtualizationRefreshCachedGroups
 */

params ["_now", "_stats", "_groups"];

private _groupIds = FLO_VirtUpdate get "cachedGroupIds";
private _lastGroupCache = FLO_VirtUpdate get "lastGroupCacheTime";
if (_now - _lastGroupCache < 1 && {count _groupIds == count _groups}) exitWith { _groupIds };

private _groupCacheStart = diag_tickTime;
_groupIds = keys _groups;
FLO_VirtUpdate set ["cachedGroupIds", _groupIds];
FLO_VirtUpdate set ["lastGroupCacheTime", _now];

private _activeGroups = 0;
private _activeUnits = 0;
private _deferredGroups = 0;
{
    private _gData = _groups get _x;
    if (_gData get "isActive") then {
        _activeGroups = _activeGroups + 1;
        _activeUnits = _activeUnits + ([_gData, false] call FLO_fnc_virtualizationGetGroupUnitLoad);
    };
    if (_gData get "activationDeferred") then {
        _deferredGroups = _deferredGroups + 1;
    };
} forEach _groupIds;

FLO_VirtUpdate set ["activeUnitCount", _activeUnits];
_stats set ["totalGroupsLast", count _groupIds];
_stats set ["activeGroupsLast", _activeGroups];
_stats set ["inactiveGroupsLast", (count _groupIds) - _activeGroups];
_stats set ["activeUnitsLast", _activeUnits];
_stats set ["activationCapLast", FLO_virtualGroups get "_activationUnitCap"];
_stats set ["deferredGroupsLast", _deferredGroups];

private _groupCacheMs = (diag_tickTime - _groupCacheStart) * 1000;
_stats set ["lastGroupCacheMs", _groupCacheMs];
if (_groupCacheMs > (_stats get "peakGroupCacheMs")) then {
    _stats set ["peakGroupCacheMs", _groupCacheMs];
};

_groupIds
