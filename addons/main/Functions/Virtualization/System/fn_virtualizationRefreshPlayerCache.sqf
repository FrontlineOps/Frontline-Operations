/*
 * Function: FLO_fnc_virtualizationRefreshPlayerCache
 */

params ["_now", "_stats"];

private _lastCache = FLO_VirtUpdate get "lastPlayerCacheTime";
private _playerCacheInterval = FLO_VirtUpdate get "playerCacheInterval";
if (_now - _lastCache < _playerCacheInterval) exitWith { false };

private _cachePlayersStart = diag_tickTime;
call FLO_fnc_virtualizationCachePlayers;
private _cachePlayersMs = (diag_tickTime - _cachePlayersStart) * 1000;

_stats set ["lastPlayerCacheMs", _cachePlayersMs];
if (_cachePlayersMs > (_stats get "peakPlayerCacheMs")) then {
    _stats set ["peakPlayerCacheMs", _cachePlayersMs];
};

true
