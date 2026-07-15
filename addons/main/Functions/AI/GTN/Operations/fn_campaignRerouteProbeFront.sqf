/* Shifts surviving probe groups to another valid source-facing approach axis. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_nextSourceObjectiveId", "", [""]]
];

if !(_nextSourceObjectiveId in (_front get "sourceObjectiveIds")) then {
    throw format ["Probe front %1 cannot shift to foreign source %2", _front get "probeId", _nextSourceObjectiveId];
};
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _groupIds = (_front get "committedGroupIds") select {
    _x in _groups && {((_groups get _x) get "unitCount") > 0}
};
if (_groupIds isEqualTo []) exitWith { false };

private _assignmentId = _front get "formalOperationId";
if (_assignmentId == "") then { _assignmentId = _front get "probeId"; };
private _ownSide = _cmdr get "_ownSide";
private _rejectionCounts = createHashMap;
private _allAssignable = {
    [
        _groups get _x,
        _ownSide,
        ["infantry", "motorized", "mechanized", "armor"],
        ["ATTACK"],
        _assignmentId,
        _rejectionCounts
    ] call FLO_fnc_gtnGroupIsStrategicallyAssignable
} count _groupIds == count _groupIds;
if (!_allAssignable) exitWith {
    ["CAMPAIGN", 4, format [
        "Probe front %1 axis shift deferred source=%2 groups=%3 rejections=%4",
        _front get "probeId",
        _nextSourceObjectiveId,
        count _groupIds,
        _rejectionCounts
    ]] call FLO_fnc_log;
    false
};

private _objectiveId = _front get "objectiveId";
private _objective = FLO_Objectives get _objectiveId;
private _routes = [
    _director,
    _objectiveId,
    _objective,
    (FLO_Objectives get _nextSourceObjectiveId) get "position",
    _groupIds,
    _groups
] call FLO_fnc_campaignBuildAssaultApproachLanes;
if ((count (keys _routes)) != count _groupIds) then {
    throw format ["Probe front %1 reroute count %2 does not match groups %3", _front get "probeId", count (keys _routes), count _groupIds];
};
private _previousRoutes = createHashMap;
{
    _previousRoutes set [_x, +((_groups get _x) get "waypoints")];
} forEach _groupIds;
private _rerouted = [];
{
    if !([_cmdr, _x, _routes get _x, _objectiveId, _assignmentId] call FLO_fnc_gtnRetaskAttackRoute) exitWith {};
    _rerouted pushBack _x;
} forEach _groupIds;
if ((count _rerouted) != count _groupIds) exitWith {
    {
        [_x, _previousRoutes get _x, true, "PROBE_AXIS_ROLLBACK"] call FLO_fnc_updateVirtualGroupWaypoints;
    } forEach _groupIds;
    false
};

_front set ["primarySourceObjectiveId", _nextSourceObjectiveId];
_front set ["axisRevision", (_front get "axisRevision") + 1];
_front set ["bestDistance", 1e12];
_front set ["progressSamples", 0];
_front set ["stalledSamples", 0];
_front set ["lastContactAt", -1];
_front set ["nextActionAtDateNum", call FLO_fnc_operationalDateNumber];
["CAMPAIGN", 3, format [
    "Probe front %1 shifted %2 groups to axis %3",
    _front get "probeId",
    count _groupIds,
    _nextSourceObjectiveId
]] call FLO_fnc_log;
true
