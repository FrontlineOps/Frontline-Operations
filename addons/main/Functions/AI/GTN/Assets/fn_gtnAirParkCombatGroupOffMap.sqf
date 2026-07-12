/* Parks one non-transport combat-air group at its deterministic reserve. */
params [
    ["_groupId", "", [""]],
    ["_clearMissionState", true, [true]]
];

private _groups = call FLO_fnc_virtualizationGetGroupMap;
if !(_groupId in _groups) exitWith { false };
private _groupData = _groups get _groupId;
private _groupType = _groupData get "groupType";
if !(_groupType in ["helicopter", "air", "jet"]) exitWith { false };
if (_groupData get "transportRole") exitWith { false };

private _homeObjective = _groupData get "homeObjective";
if (_homeObjective == "") then {
    throw format ["Combat aircraft %1 has no homeObjective", _groupId];
};
if !(_homeObjective in FLO_Objectives) then {
    throw format ["Combat aircraft %1 references missing home objective %2", _groupId, _homeObjective];
};

if (_groupData get "isActive") then {
    if !([_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup) exitWith { false };
};

private _homePos = (FLO_Objectives get _homeObjective) get "position";
private _routePositions = [_groupData get "side", _homePos] call FLO_fnc_gtnAirResolveReserveRoutePositions;
private _reservePos = _routePositions select 0;

[_groupId, [], false, false, "GTN_AIR_RESERVE"] call FLO_fnc_updateVirtualGroupWaypoints;
private _changes = createHashMapFromArray [
    ["forceVirtual", true],
    ["noWaypoints", true],
    ["direction", [90, 270] select ((_groupData get "side") isEqualTo east)]
];
if (_clearMissionState) then {
    _changes set ["missionLock", ""];
    _changes set ["missionType", ""];
    _changes set ["executionState", ""];
};
[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;
[_groupId, _reservePos] call FLO_fnc_virtualizationUpdateGroupPosition;

true
