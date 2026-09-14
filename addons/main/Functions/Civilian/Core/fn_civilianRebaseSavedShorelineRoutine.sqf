/* Rebase a current ambient routine's flooded shoreline endpoint, preserving its
   activity and anchors. Military orders, mission locks and deep-water goals fail. */
params ["_savedData", "_groupId"];
if !((_savedData get "groupType") in ["civilian", "civ_pedestrian", "civilianVehicle", "civ_car"]) exitWith { false };
if !((_savedData get "pathSource") in ["CIV_ROUTINE_HOME", "CIV_ROUTINE_RETURN", "CIV_ROUTINE_SHELTER", "CIV_ROUTINE_WORK", "CIV_ROUTINE_MARKET", "CIV_ROUTINE_OBSERVE"]) exitWith { false };
if ((_savedData get "commanderOrder") != "" || {(_savedData get "missionLock") != ""}
    || {(_savedData get "attachedTo") != ""} || {(_savedData get "mountedIn") != ""}
    || {(_savedData get "attachedGroups") isNotEqualTo []}) exitWith { false };

private _corrections = [];
private _rejected = false;
{
    private _position = _x select 0;
    if (!surfaceIsWater _position) then { continue };
    if (getTerrainHeightASL _position < -1) exitWith { _rejected = true };
    if ((_corrections findIf { (_x select 0) isEqualTo _position }) >= 0) then { continue };
    private _shore = [_position, 50, 1] call FLO_fnc_getSafeLandPos;
    if (surfaceIsWater _shore || {getTerrainHeightASL _shore < 1} || {_shore distance2D _position > 50.1}) exitWith { _rejected = true };
    _corrections pushBack [+_position, [_shore select 0, _shore select 1, 0]];
} forEach (_savedData get "waypoints");
if (_rejected || {_corrections isEqualTo []}) exitWith { false };

private _rebase = {
    params ["_position"];
    private _index = _corrections findIf { (_x select 0) isEqualTo _position };
    if (_index < 0) exitWith { +_position };
    +((_corrections select _index) select 1)
};
_savedData set ["waypoints", (_savedData get "waypoints") apply {
    private _waypoint = +_x;
    _waypoint set [0, [_waypoint select 0] call _rebase];
    _waypoint
}];
{
    _savedData set [_x, [_savedData get _x] call _rebase];
} forEach ["civilianAnchorPos", "civilianHomeAnchorPos", "civilianRoutineAnchorPos"];
_savedData set ["civilianRouteAnchors", (_savedData get "civilianRouteAnchors") apply { [_x] call _rebase }];
["CIVILIAN", 2, format ["Rebased flooded routine endpoints group=%1 endpoints=%2 maximumShift=50m", _groupId, count _corrections]] call FLO_fnc_log;
true
