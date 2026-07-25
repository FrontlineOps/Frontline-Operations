/* Requests one paid artillery mission to break a stalled direct-attack engagement. */
params [
    ["_zoneId", "", [""]],
    ["_zonePos", [0, 0, 0], [[]]],
    ["_eastRefs", [], [[]]],
    ["_westRefs", [], [[]]],
    ["_supportAvailability", createHashMap, [createHashMap]],
    ["_outcome", createHashMap, [createHashMap]]
];

if (_outcome get "decisive") exitWith { "" };

private _manager = call FLO_fnc_gtnArtilleryManager;
if ((_outcome get "roundCount") < (_manager get "virtualCombatStallRounds")) exitWith { "" };
if ((_outcome get "effectiveRatio") > (_manager get "virtualCombatMaximumRatio")) exitWith { "" };
if (abs (_outcome get "momentum") > (_manager get "virtualCombatMaximumMomentum")) exitWith { "" };

private _state = call FLO_fnc_gtnCombatGetState;
private _engagement = (_state get "engagements") get _zoneId;
if (diag_tickTime < (_engagement get "artilleryReadyAt")) exitWith { "" };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _eastAttackRefs = [];
private _westAttackRefs = [];
{
    private _groupId = _x select 0;
    if !(_groupId in _groups) then { continue };
    private _groupData = _groups get _groupId;
    if ((_groupData get "unitCount") <= 0) then { continue };
    if ((_groupData get "commanderOrder") != "ATTACK") then { continue };
    _eastAttackRefs pushBack [_groupId, _groupData];
} forEach _eastRefs;
{
    private _groupId = _x select 0;
    if !(_groupId in _groups) then { continue };
    private _groupData = _groups get _groupId;
    if ((_groupData get "unitCount") <= 0) then { continue };
    if ((_groupData get "commanderOrder") != "ATTACK") then { continue };
    _westAttackRefs pushBack [_groupId, _groupData];
} forEach _westRefs;

private _requestSide = sideUnknown;
private _attackerRefs = [];
private _targetRefs = [];
if (_eastAttackRefs isNotEqualTo [] && {_westAttackRefs isEqualTo []}) then {
    _requestSide = east;
    _attackerRefs = _eastAttackRefs;
    _targetRefs = _westRefs;
};
if (_westAttackRefs isNotEqualTo [] && {_eastAttackRefs isEqualTo []}) then {
    _requestSide = west;
    _attackerRefs = _westAttackRefs;
    _targetRefs = _eastRefs;
};
if !(_requestSide in [east, west]) exitWith { "" };

private _sideKey = [_requestSide] call FLO_fnc_sideKey;
if !(_supportAvailability get (_sideKey + "_ARTY")) exitWith { "" };

private _reportedTargetRefs = [];
{
    private _groupId = _x select 0;
    if !(_groupId in _groups) then { continue };
    private _groupData = _groups get _groupId;
    if (_groupData get "isActive") then { continue };
    if ((_groupData get "unitCount") <= 0) then { continue };
    _reportedTargetRefs pushBack [_groupId, _groupData];
} forEach _targetRefs;
if (_reportedTargetRefs isEqualTo []) exitWith { "" };

private _targetPos = [_reportedTargetRefs] call FLO_fnc_gtnCombatAveragePosition;
if ([_targetPos] call FLO_fnc_virtualizationIsPositionWithinActivationRange) exitWith { "" };

private _objectiveId = ((_attackerRefs select 0) select 1) get "attackObjective";
if (_objectiveId == "") then {
    private _message = format ["Stalemate artillery received ATTACK group %1 without an objective", (_attackerRefs select 0) select 0];
    ["VIRTUAL COMBAT", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _targetContext = createHashMapFromArray [
    ["targetGroupIds", _reportedTargetRefs apply { _x select 0 }],
    ["engagementZoneId", _zoneId],
    ["contactState", "ENGAGEMENT"]
];
private _requested = _manager call ["_requestFireMission", [
    _targetPos,
    _manager get "virtualCombatRounds",
    _manager get "virtualCombatAccuracy",
    _requestSide,
    _objectiveId,
    "VIRTUAL_COMBAT",
    false,
    _targetContext
]];
if (!_requested) exitWith { "" };

_engagement set ["artilleryReadyAt", diag_tickTime + (_manager get "virtualCombatZoneCooldownSeconds")];
_engagement set ["artilleryMissionCount", (_engagement get "artilleryMissionCount") + 1];
_engagement set ["lastArtillerySide", _sideKey];

["GTN_COMBAT", 3, format [
    "%1 committed artillery to stalled engagement %2 after round %3",
    _sideKey,
    _zoneId,
    _outcome get "roundCount"
]] call FLO_fnc_log;

_sideKey
