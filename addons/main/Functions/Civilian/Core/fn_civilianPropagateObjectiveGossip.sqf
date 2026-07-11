/*
 * Function: FLO_fnc_civilianPropagateObjectiveGossip
 * Author: Frontline Operations Development Group
 * Description:
 *   Propagates civilian rumor memories across linked objectives with
 *   confidence decay and bounded spread depth.
 *
 * Arguments:
 * 0: Objective memory ledger <HASHMAP>
 * 1: Gossip cursor <NUMBER>
 * 2: Current time tick <NUMBER>
 *
 * Return Value:
 * ARRAY [addedCount, nextCursor]
 */

params [
    ["_ledger", createHashMap, [createHashMap]],
    ["_cursor", 0, [0]],
    ["_nowTick", diag_tickTime, [0]]
];

if (isNil "FLO_Objectives") exitWith { [0, 0] };

private _objectiveIds = keys FLO_Objectives;
private _objectiveCount = count _objectiveIds;
if (_objectiveCount == 0) exitWith { [0, 0] };

private _batchSize = (FLO_CivilianConfig get "GOSSIP_BATCH_SIZE") min _objectiveCount;
private _decay = FLO_CivilianConfig get "GOSSIP_DECAY";
private _maxDepth = FLO_CivilianConfig get "GOSSIP_MAX_DEPTH";
private _spreadInterval = FLO_CivilianConfig get "GOSSIP_SPREAD_INTERVAL";
private _addedCount = 0;

for "_i" from 0 to (_batchSize - 1) do {
    private _objectiveId = _objectiveIds select ((_cursor + _i) mod _objectiveCount);
    if !(_objectiveId in _ledger) then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    private _linkedObjectives = _objective get "linkedObjectives";
    private _records = +(_ledger get _objectiveId);
    private _activeRecords = [];

    {
        private _record = _x;
        if ((_record get "expiresAt") <= _nowTick) then { continue };

        _activeRecords pushBack _record;

        if ((_record get "gossipDepth") >= _maxDepth) then { continue };
        if ((_record get "lastSpreadAt") >= 0 && {(_nowTick - (_record get "lastSpreadAt")) < _spreadInterval}) then { continue };

        {
            private _targetObjectiveId = _x;
            if (_targetObjectiveId == (_record get "previousObjectiveId")) then { continue };
            if (_targetObjectiveId == (_record get "sourceObjectiveId") && {(_record get "gossipDepth") > 0}) then { continue };

            private _targetObjective = FLO_Objectives get _targetObjectiveId;
            private _targetPos = +(_targetObjective get "position");
            private _radius = ((_targetObjective get "radius") min 120) max 30;
            private _reportPos = _targetPos getPos [30 + random _radius, random 360];
            _reportPos set [2, 0];

            private _remainingLifetime = (_record get "expiresAt") - _nowTick;
            private _expiresAt = (_record get "expiresAt") min (_nowTick + ((_remainingLifetime * 0.75) max 60));
            private _confidence = (_record get "confidence") * _decay;
            if (_confidence < 0.18) then { continue };

            private _gossipRecord = createHashMapFromArray [
                ["objectiveId", _targetObjectiveId],
                ["sourceObjectiveId", _record get "sourceObjectiveId"],
                ["previousObjectiveId", _objectiveId],
                ["reportType", _record get "reportType"],
                ["position", _reportPos],
                ["confidence", _confidence],
                ["gossipDepth", (_record get "gossipDepth") + 1],
                ["firstSeenAt", _record get "firstSeenAt"],
                ["lastUpdatedAt", _nowTick],
                ["expiresAt", _expiresAt],
                ["lastSpreadAt", -1],
                ["summary", _record get "summary"]
            ];

            [_ledger, _gossipRecord, _nowTick] call FLO_fnc_civilianMergeObjectiveMemory;
            _addedCount = _addedCount + 1;
        } forEach _linkedObjectives;

        _record set ["lastSpreadAt", _nowTick];
    } forEach _records;

    _ledger set [_objectiveId, _activeRecords];
};

[_addedCount, (_cursor + _batchSize) mod _objectiveCount]
