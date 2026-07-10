/*
 * Function: FLO_fnc_virtualizationCachePlayers
 */

private _cached = [];
private _headlessClients = entities "HeadlessClient_F";
{
    if (
        alive _x
        && {!(_x in _headlessClients)}
        && {(side group _x) in [east, west, independent]}
    ) then {
        private _veh = vehicle _x;
        private _inAir = (_veh != _x) && {_veh isKindOf "Air"};
        _cached pushBack [getPosATL _x, _inAir];
    };
} forEach allPlayers;

FLO_VirtUpdate set ["cachedPlayerPositions", _cached];
FLO_VirtUpdate set ["lastPlayerCacheTime", diag_tickTime];

_cached
