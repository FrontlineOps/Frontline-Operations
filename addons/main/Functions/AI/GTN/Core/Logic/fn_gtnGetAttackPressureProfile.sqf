/*
 * Function: FLO_fnc_gtnGetAttackPressureProfile
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Builds a shared offensive pressure profile for one frontline objective so
 *   attack caps, cooldowns, and objective selection all react to the
 *   same capture streak and overextension state.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAP>
 *   1: Objective ID <STRING>
 *
 * Return Value:
 *   HASHMAP
 */

params [
    ["_cmdr", nil],
    ["_objectiveId", ""]
];

private _profile = createHashMapFromArray [
    ["recentCaptureCount", 0],
    ["captureStreakSteps", 0],
    ["overextensionSteps", 0],
    ["capMultiplier", 1],
    ["spentSecondsBonus", 0],
    ["selectionPenaltyMeters", 0],
    ["bestSourceObjectiveId", ""],
    ["bestSourceDepth", -1],
    ["bestSourceRouteMeters", 1e12],
    ["bestSourceActiveNode", false],
    ["bestSourceRecentlyCaptured", false]
];

if (isNil "_cmdr" || {_objectiveId == ""}) exitWith { _profile };

private _cache = _cmdr get "_attackPressureProfiles";
if (_objectiveId in _cache) exitWith { _cache get _objectiveId };

private _config = _cmdr get "_config";
private _ownSide = _cmdr get "_ownSide";
private _ws = _cmdr get "_worldState";
private _objectives = _ws call ["_getObjectives", []];
private _nowDateNum = call FLO_fnc_operationalDateNumber;
private _recentCaptureCount = if ("__recentCaptureCount" in _cache) then {
    _cache get "__recentCaptureCount"
} else {
    private _captureStreakWindowSeconds = _config get "captureStreakWindowSeconds";
    private _count = 0;

    {
        private _objective = _y;
        if ((_objective get "owner") != _ownSide) then { continue };

        private _capturedAtDateNum = _objective get "capturedAtDateNum";
        if (_capturedAtDateNum < 0) then { continue };
        private _captureAgeSeconds = [_capturedAtDateNum, _nowDateNum] call FLO_fnc_dateNumberDeltaSeconds;
        if (_captureAgeSeconds > _captureStreakWindowSeconds) then { continue };

        _count = _count + 1;
    } forEach _objectives;

    _cache set ["__recentCaptureCount", _count];
    _count
};
private _captureStreakSteps = if ("__captureStreakSteps" in _cache) then {
    _cache get "__captureStreakSteps"
} else {
    private _steps = ((_recentCaptureCount - 1) max 0) min (_config get "captureStreakMaxSteps");
    _cache set ["__captureStreakSteps", _steps];
    _steps
};
_profile set ["recentCaptureCount", _recentCaptureCount];
_profile set ["captureStreakSteps", _captureStreakSteps];

private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];
if (_sourceObjectives isNotEqualTo []) then {
    private _sideKey = _cmdr get "_sideKey";
    private _net = FLO_Logistics_Networks get _sideKey;
    private _recentSourceWindowSeconds = _config get "attackOverextensionRecentCaptureSeconds";
    private _bestDepthRank = 1e12;
    private _bestActiveNode = false;
    private _bestRouteMeters = 1e12;
    private _bestSourceObjectiveId = "";
    private _bestSourceDepth = -1;
    private _bestSourceRecentlyCaptured = false;

    {
        private _sourceObjectiveId = _x;
        private _sourceObjective = FLO_Objectives get _sourceObjectiveId;
        private _role = [_net, _sourceObjectiveId] call FLO_fnc_logisticsNetworkDescribeObjectiveSupplyRole;
        private _depth = _role get "depth";
        private _routeMeters = _role get "routeMeters";
        private _activeNode = _role get "isActiveNode";
        private _capturedAtDateNum = _sourceObjective get "capturedAtDateNum";
        private _recentlyCaptured = _capturedAtDateNum >= 0 && {
            ([_capturedAtDateNum, _nowDateNum] call FLO_fnc_dateNumberDeltaSeconds) <= _recentSourceWindowSeconds
        };
        private _depthRank = [1e12, _depth] select (_depth >= 0);

        if (
            _bestSourceObjectiveId == ""
            || {_depthRank < _bestDepthRank}
            || {_depthRank == _bestDepthRank && {_activeNode && !_bestActiveNode}}
            || {_depthRank == _bestDepthRank && {_activeNode isEqualTo _bestActiveNode} && {_routeMeters < _bestRouteMeters}}
        ) then {
            _bestDepthRank = _depthRank;
            _bestActiveNode = _activeNode;
            _bestRouteMeters = _routeMeters;
            _bestSourceObjectiveId = _sourceObjectiveId;
            _bestSourceDepth = _depth;
            _bestSourceRecentlyCaptured = _recentlyCaptured;
        };
    } forEach _sourceObjectives;

    private _overextensionSteps = 0;
    if (_bestSourceDepth < 0) then {
        _overextensionSteps = _overextensionSteps + (_config get "attackOverextensionDisconnectedSteps");
    } else {
        private _depthThreshold = _config get "attackOverextensionDepthThreshold";
        if (_bestSourceDepth >= _depthThreshold) then {
            _overextensionSteps = _overextensionSteps + ((_bestSourceDepth - _depthThreshold) + 1);
        };
    };
    if (_bestSourceRecentlyCaptured) then {
        _overextensionSteps = _overextensionSteps + 1;
    };
    _profile set ["overextensionSteps", _overextensionSteps];
    _profile set ["bestSourceObjectiveId", _bestSourceObjectiveId];
    _profile set ["bestSourceDepth", _bestSourceDepth];
    _profile set ["bestSourceRouteMeters", _bestRouteMeters];
    _profile set ["bestSourceActiveNode", _bestActiveNode];
    _profile set ["bestSourceRecentlyCaptured", _bestSourceRecentlyCaptured];
};

private _capPenalty = (_captureStreakSteps * (_config get "captureStreakCapPenaltyPerStep"))
    + ((_profile get "overextensionSteps") * (_config get "attackOverextensionCapPenaltyPerStep"));
private _capMultiplier = (1 - _capPenalty) max (_config get "attackPressureMinimumCapMultiplier");
private _spentSecondsBonus = (_captureStreakSteps * (_config get "captureStreakSpentSecondsPerStep"))
    + ((_profile get "overextensionSteps") * (_config get "attackOverextensionSpentSecondsPerStep"));
private _selectionPenaltyMeters = (_profile get "overextensionSteps") * (_config get "attackOverextensionSelectionPenaltyMetersPerStep");

_profile set ["capMultiplier", _capMultiplier];
_profile set ["spentSecondsBonus", _spentSecondsBonus];
_profile set ["selectionPenaltyMeters", _selectionPenaltyMeters];

_cache set [_objectiveId, _profile];
_profile
