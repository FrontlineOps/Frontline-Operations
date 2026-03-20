/*
 * Function: FLO_fnc_gtnArtilleryGetAvailableGroups
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns cached artillery groups that are currently usable for a fire
 *   mission, filtered by request side and excluding groups already on mission.
 *
 * Arguments:
 * 0: Artillery Manager <HASHMAP>
 * 1: Request Side <SIDE>
 *
 * Return Value:
 * Array - [[groupId, groupData], ...]
 */

params ["_manager", ["_requestSide", sideUnknown]];

private _cache = _manager get "artilleryGroupsBySide";
private _cacheKey = "ALL";
if (_requestSide isEqualTo east) then { _cacheKey = "EAST"; };
if (_requestSide isEqualTo west) then { _cacheKey = "WEST"; };

private _groupMap = FLO_virtualGroups get "_groups";
private _missions = _manager get "missions";
private _available = [];

{
    private _groupId = _x;

    if (_groupId in _missions) then { continue };

    if !(_groupId in _groupMap) then {
        [_manager, _groupId, nil, false] call FLO_fnc_gtnArtillerySyncCachedGroup;
        continue;
    };

    private _groupData = _groupMap get _groupId;
    if ((_groupData get "groupType") != "artillery") then {
        [_manager, _groupId, nil, false] call FLO_fnc_gtnArtillerySyncCachedGroup;
        continue;
    };

    if (_requestSide in [east, west] && { (_groupData get "side") != _requestSide }) then {
        continue;
    };

    _available pushBack [_groupId, _groupData];
} forEach (keys (_cache get _cacheKey));

_available
