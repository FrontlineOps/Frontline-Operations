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

private _routePositions = [_groupData] call FLO_fnc_gtnAirResolveReserveRoutePositions;
_routePositions params ["_reservePos", "_ingressPos"];

private _deactivationSucceeded = true;
private _removedDuringDeactivation = false;
if (_groupData get "isActive") then {
    _deactivationSucceeded = [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
    if (_deactivationSucceeded) then {
        if (_groupId in _groups) then {
            _groupData = _groups get _groupId;
        } else {
            _removedDuringDeactivation = true;
        };
    };
};
if (!_deactivationSucceeded) exitWith { false };
if (_removedDuringDeactivation) exitWith {
    ["GTN Air Asset Manager", 3, format [
        "Air asset %1 removed during reserve parking after zero-strength synchronization",
        _groupId
    ]] call FLO_fnc_log;
    true
};

[_groupId, [], false, "GTN_AIR_RESERVE"] call FLO_fnc_updateVirtualGroupWaypoints;
private _changes = createHashMapFromArray [
    ["forceVirtual", true],
    ["noWaypoints", true],
    ["direction", _reservePos getDir _ingressPos]
];
if (_clearMissionState) then {
    _changes set ["missionLock", ""];
    _changes set ["missionType", ""];
    _changes set ["executionState", ""];
};
[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;
[_groupId, _reservePos] call FLO_fnc_virtualizationUpdateGroupPosition;

["GTN Air", 5, format [
    "Parked combat-air group %1 home=%2 reserve=%3 ingress=%4",
    _groupId,
    _groupData get "homeObjective",
    _reservePos,
    _ingressPos
]] call FLO_fnc_log;

true
