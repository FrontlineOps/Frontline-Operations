/*
 * Function: FLO_fnc_civilianIngestCombatEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Converts maintained GTN combat telemetry into objective witness memories
 *   for the civilian manager.
 *
 * Arguments:
 * 0: Objective memory ledger <HASHMAP>
 * 1: Last processed combat-event tick <NUMBER>
 * 2: Current time tick <NUMBER>
 *
 * Return Value:
 * ARRAY [latestProcessedAt, addedCount]
 */

params [
    ["_ledger", createHashMap, [createHashMap]],
    ["_lastProcessedAt", -1, [0]],
    ["_nowTick", diag_tickTime, [0]]
];

if (isNil "FLO_GTN_CombatEvents") exitWith { [_lastProcessedAt, 0] };

private _retention = FLO_CivilianConfig get "MEMORY_RETENTION_SECONDS";
private _latestProcessedAt = _lastProcessedAt;
private _addedCount = 0;

{
    private _eventTime = _x get "time";
    if (_eventTime <= _lastProcessedAt) then { continue };

    if (_eventTime > _latestProcessedAt) then {
        _latestProcessedAt = _eventTime;
    };

    if ((_eventTime + _retention) <= _nowTick) then { continue };

    private _objectiveId = _x get "objectiveId";
    if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) then { continue };

    private _eastGroups = _x get "eastGroupCount";
    private _westGroups = _x get "westGroupCount";
    private _combinedGroups = _eastGroups + _westGroups;
    private _survivors = (_x get "eastAfter") + (_x get "westAfter");
    private _margin = _x get "margin";

    private _reportType = switch (true) do {
        case (_combinedGroups >= 5 || {_survivors >= 24}): { "HOSTILE_REPORT" };
        case (_combinedGroups >= 3 || {_margin >= 3}): { "CHECKPOINT_RUMOR" };
        default { "PATROL_SIGHTING" };
    };

    private _confidence = 0.55 + ((_combinedGroups min 4) * 0.08);
    if (_margin >= 3) then {
        _confidence = _confidence + 0.05;
    };
    if (_confidence > 0.9) then {
        _confidence = 0.9;
    };

    private _summary = switch (_reportType) do {
        case "HOSTILE_REPORT": { "heavy fighting was reported" };
        case "CHECKPOINT_RUMOR": { "armed men were stopping movement" };
        default { "an armed patrol was seen" };
    };

    private _memory = createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["sourceObjectiveId", _objectiveId],
        ["previousObjectiveId", ""],
        ["reportType", _reportType],
        ["position", _x get "position"],
        ["confidence", _confidence],
        ["gossipDepth", 0],
        ["firstSeenAt", _eventTime],
        ["lastUpdatedAt", _nowTick],
        ["expiresAt", _eventTime + _retention],
        ["lastSpreadAt", -1],
        ["summary", _summary]
    ];

    [_ledger, _memory, _nowTick] call FLO_fnc_civilianMergeObjectiveMemory;
    _addedCount = _addedCount + 1;
} forEach FLO_GTN_CombatEvents;

[_latestProcessedAt, _addedCount]
