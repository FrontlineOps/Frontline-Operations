/*
 * Function: FLO_fnc_minefieldBuildJobStep
 * Author: Frontline Operations Development Group
 * Description:
 *   Advances one staged minefield build job by one chunk.
 *
 * Arguments:
 * 0: Job ID <STRING>
 *
 * Return Value:
 * STRING - "requeue", "done", or "drop"
 */

params [["_jobId", ""]];

if (_jobId == "") exitWith { "drop" };

private _state = FLO_MinefieldBuild;
private _jobs = _state get "jobs";
if !(_jobId in _jobs) exitWith { "drop" };

private _job = _jobs get _jobId;
private _objectiveId = _job get "objectiveId";
private _objective = FLO_Objectives get _objectiveId;
private _objectiveIndex = _state get "objectiveIndex";
private _activePlayerSide = FLO_ActivePlayerSide;
private _playerProximityMeters = (FLO_virtualGroups get "_activationDistance") + (FLO_MinefieldConfig get "playerProximityActivationBufferMeters");

if ((_objective get "owner") != (_job get "side")) exitWith {
    [_jobId, "STALE_OWNER"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

if !(_activePlayerSide in [east, west]) exitWith {
    [_jobId, "PLAYER_SIDE_NOT_LOCKED"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

if ((_job get "side") isEqualTo _activePlayerSide) exitWith {
    [_jobId, "PLAYER_FRIENDLY_OBJECTIVE"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

if !([_objectiveId, _activePlayerSide, _playerProximityMeters] call FLO_fnc_minefieldObjectiveHasNearbyPlayer) exitWith {
    [_jobId, "NO_NEARBY_PLAYER"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

if ((_job get "stage") != "commit" && {_objectiveId in FLO_MinefieldObjectiveIndex}) exitWith {
    [_jobId, "ALREADY_EXISTS"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

if !(_objectiveId in _objectiveIndex) exitWith {
    [_jobId, "SUPERSEDED"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

if ((_objectiveIndex get _objectiveId) != _jobId) exitWith {
    [_jobId, "SUPERSEDED"] call FLO_fnc_minefieldFinalizeBuildJob;
    "done"
};

_job set ["slices", (_job get "slices") + 1];
private _metrics = _job get "metrics";

switch (_job get "stage") do {
    case "resolve": {
        private _resolveStatus = [_job] call FLO_fnc_minefieldResolveFrontlineAnchorJobStep;
        if (_resolveStatus == "pending") exitWith { "requeue" };
        if (_resolveStatus == "failed") exitWith {
            [_jobId, _metrics get "reason"] call FLO_fnc_minefieldFinalizeBuildJob;
            "done"
        };

        _job set ["stage", "packets"];
        "requeue"
    };

    case "packets": {
        private _tPackets = diag_tickTime;
        private _context = _job get "context";
        private _packets = [_context] call FLO_fnc_minefieldBuildObjectivePackets;
        private _layoutStats = _job get "layoutStats";
        private _laneCount = 0;

        {
            private _packetSlotSpacing = (_x get "slotSpacing") max 1;
            private _packetLaneCount = ((floor (((_x get "halfWidth") * 2) / _packetSlotSpacing)) + 1) max 2;
            _laneCount = _laneCount + _packetLaneCount;

            switch (_x get "role") do {
                case "road": {
                    _layoutStats set ["roadPacketCount", (_layoutStats get "roadPacketCount") + 1];
                };
                case "cover": {
                    _layoutStats set ["coverPacketCount", (_layoutStats get "coverPacketCount") + 1];
                };
                case "bypass": {
                    _layoutStats set ["bypassPacketCount", (_layoutStats get "bypassPacketCount") + 1];
                };
                default {
                    _layoutStats set ["frontagePacketCount", (_layoutStats get "frontagePacketCount") + 1];
                };
            };
        } forEach _packets;

        _metrics set ["packetBuildMs", (_metrics get "packetBuildMs") + ((diag_tickTime - _tPackets) * 1000)];
        _metrics set ["packetCount", count _packets];
        _job set ["packets", _packets];
        _job set ["laneCount", _laneCount];

        if ((count _packets) == 0) exitWith {
            [_jobId, "NO_PACKETS"] call FLO_fnc_minefieldFinalizeBuildJob;
            "done"
        };

        _job set ["stage", "layout"];
        "requeue"
    };

    case "layout": {
        private _packets = _job get "packets";
        private _packetIndex = _job get "packetIndex";
        private _context = _job get "context";
        private _spacingIndex = _job get "spacingIndex";
        private _layoutStats = _job get "layoutStats";
        private _mineSpecs = _job get "layoutMineSpecs";
        if (_packetIndex >= count _packets) exitWith {
            [_jobId, "NO_PACKETS"] call FLO_fnc_minefieldFinalizeBuildJob;
            "done"
        };

        private _packet = _packets select _packetIndex;
        private _packetState = _job get "packetState";
        private _slotBatch = (FLO_MinefieldConfig get "buildLayoutSlotBatch") max 1;
        private _tPacket = diag_tickTime;
        private _stepResult = [_context, _packet, _spacingIndex, _layoutStats, _packetState, _slotBatch] call FLO_fnc_minefieldBuildPacketMineSpecsStep;
        private _packetBuildMs = (diag_tickTime - _tPacket) * 1000;

        switch (_packet get "role") do {
            case "road": {
                _metrics set ["roadBuildMs", (_metrics get "roadBuildMs") + _packetBuildMs];
            };
            case "cover": {
                _metrics set ["coverBuildMs", (_metrics get "coverBuildMs") + _packetBuildMs];
            };
            case "bypass": {
                _metrics set ["bypassBuildMs", (_metrics get "bypassBuildMs") + _packetBuildMs];
            };
            default {
                _metrics set ["frontageBuildMs", (_metrics get "frontageBuildMs") + _packetBuildMs];
            };
        };
        _metrics set ["layoutMs", (_metrics get "layoutMs") + _packetBuildMs];

        {
            _mineSpecs pushBack _x;
        } forEach (_stepResult get "mineSpecs");

        _packetState = _stepResult get "state";
        if (_stepResult get "done") then {
            _packetIndex = _packetIndex + 1;
            _packetState = createHashMap;
        };

        _job set ["packetIndex", _packetIndex];
        _job set ["packetState", _packetState];

        if (_packetIndex < count _packets) exitWith { "requeue" };

        _metrics set ["plannedMineCount", count _mineSpecs];
        _metrics set ["laneCount", _job get "laneCount"];
        _metrics set ["layerCount", (_context get "layerCount")];
        _metrics set ["attemptedSlots", _layoutStats get "attemptedSlots"];
        _metrics set ["acceptedDirectSlots", _layoutStats get "acceptedDirectSlots"];
        _metrics set ["acceptedFallbackSlots", _layoutStats get "acceptedFallbackSlots"];
        _metrics set ["rejectedNoSafePos", _layoutStats get "rejectedNoSafePos"];
        _metrics set ["rejectedWater", _layoutStats get "rejectedWater"];
        _metrics set ["rejectedDefendedObjective", _layoutStats get "rejectedDefendedObjective"];
        _metrics set ["rejectedForeignObjective", _layoutStats get "rejectedForeignObjective"];
        _metrics set ["rejectedSpacing", _layoutStats get "rejectedSpacing"];

        if ((count _mineSpecs) == 0) exitWith {
            [_jobId, "NO_VALID_SLOTS"] call FLO_fnc_minefieldFinalizeBuildJob;
            "done"
        };

        _job set ["stage", "budget"];
        "requeue"
    };

    case "budget": {
        private _tBudget = diag_tickTime;
        private _mineSpecs = _job get "layoutMineSpecs";
        private _budget = [(_job get "sideKey"), count _mineSpecs] call FLO_fnc_minefieldResolveResourceBudget;

        _metrics set ["budgetMs", (_metrics get "budgetMs") + ((diag_tickTime - _tBudget) * 1000)];
        _metrics set ["affordableMineCount", _budget get "affordableMineCount"];

        if ((_budget get "affordableMineCount") <= 0) exitWith {
            [_jobId, "INSUFFICIENT_RESOURCES"] call FLO_fnc_minefieldFinalizeBuildJob;
            "done"
        };

        private _rankedMineSpecs = [_mineSpecs, [], { _x get "priority" }, "DESCEND"] call BIS_fnc_sortBy;
        _job set ["selectedMineSpecs", _rankedMineSpecs select [0, _budget get "affordableMineCount"]];
        _job set ["stage", "spawn"];
        "requeue"
    };

    case "spawn": {
        private _tSpawn = diag_tickTime;
        private _selectedMineSpecs = _job get "selectedMineSpecs";
        private _spawnIndex = _job get "spawnIndex";
        private _mineObjects = _job get "mineObjects";
        private _selectedMinePositions = _job get "selectedMinePositions";
        private _fieldId = _job get "fieldId";
        private _batchSize = (FLO_MinefieldConfig get "buildSpawnBatchSize") max 1;
        private _endIndex = ((_spawnIndex + _batchSize) min (count _selectedMineSpecs)) - 1;

        if (_endIndex >= _spawnIndex) then {
            for "_specIndex" from _spawnIndex to _endIndex do {
                private _mineSpec = _selectedMineSpecs select _specIndex;
                private _mineType = _mineSpec get "type";
                private _mine = createMine [_mineType, _mineSpec get "posATL", [], 0];
                if (isNull _mine) then { continue };

                _mine setVariable ["FLO_MinefieldId", _fieldId, false];
                _mine setVariable ["FLO_MinefieldObjectiveId", _objectiveId, false];
                _mine setVariable ["FLO_MineType", _mineType, false];
                _mineObjects pushBack _mine;
                _selectedMinePositions pushBack (_mineSpec get "posATL");
            };
            _spawnIndex = _endIndex + 1;
        };

        _job set ["spawnIndex", _spawnIndex];
        _metrics set ["spawnMs", (_metrics get "spawnMs") + ((diag_tickTime - _tSpawn) * 1000)];

        if (_spawnIndex < count _selectedMineSpecs) exitWith { "requeue" };

        _metrics set ["placedMineCount", count _mineObjects];
        if ((count _mineObjects) == 0) exitWith {
            [_jobId, "NO_MINES_SPAWNED"] call FLO_fnc_minefieldFinalizeBuildJob;
            "done"
        };

        _job set ["stage", "commit"];
        "requeue"
    };

    case "commit": {
        private _commitReason = [_job] call FLO_fnc_minefieldCommitBuiltField;
        [_jobId, _commitReason] call FLO_fnc_minefieldFinalizeBuildJob;
        "done"
    };

    default {
        [_jobId, "UNKNOWN_STAGE"] call FLO_fnc_minefieldFinalizeBuildJob;
        "done"
    };
}
