if (FLO_PerformanceMonitorPfhId >= 0) exitWith {};

[
    { FLO_MissionReady },
    {
        FLO_PerformanceMonitorPfhId = [{
            if (hasInterface && {!isGameFocused}) exitWith {};

            private _now = diag_tickTime;
            private _fps = diag_fps;
            private _fpsMin = diag_fpsMin;
            private _virtWindowSeconds = 0;
            private _virtBatches = 0;
            private _virtBatchMs = 0;
            private _virtInspected = 0;
            private _virtDue = 0;
            private _virtSkipped = 0;
            private _virtMoves = 0;
            private _virtActiveSyncs = 0;
            private _virtWaypointAdvances = 0;
            private _virtPhaseSamples = 0;
            private _virtPhaseSampleMs = 0;
            private _virtPhaseProximityMs = 0;
            private _virtPhaseScheduleMs = 0;
            private _virtPhaseAttachedMs = 0;
            private _virtPhaseMovementMs = 0;
            private _virtPhasePositionUpdateMs = 0;
            private _virtPhaseCarrierSyncMs = 0;
            private _virtPhaseActivationMs = 0;
            private _virtPhaseActiveMs = 0;
            private _virtPhaseAttachedHandled = 0;
            private _virtPhaseMovementCalls = 0;
            private _virtPhasePositionUpdates = 0;
            private _virtPhaseHoldingSkips = 0;
            private _virtPhaseActiveCalls = 0;

            if (isServer) then {
                private _virtStats = FLO_VirtUpdate get "stats";
                private _lastStats = FLO_PerformanceMonitorLastVirtStats;
                private _deltas = createHashMap;
                if (FLO_PerformanceMonitorLastVirtSampleAt > 0) then {
                    _virtWindowSeconds = _now - FLO_PerformanceMonitorLastVirtSampleAt;
                    {
                        private _current = _virtStats get _x;
                        private _previous = _lastStats get _x;
                        _deltas set [_x, [_current, _current - _previous] select (_current >= _previous)];
                    } forEach keys _lastStats;
                    _virtBatches = _deltas get "batchesRunTotal";
                    _virtBatchMs = _deltas get "batchMsTotal";
                    _virtInspected = _deltas get "groupsProcessedTotal";
                    _virtDue = _deltas get "dueGroupsTotal";
                    _virtSkipped = _deltas get "scheduledSkipsTotal";
                    _virtMoves = _deltas get "virtualMovesTotal";
                    _virtActiveSyncs = _deltas get "activePositionSyncsTotal";
                    _virtWaypointAdvances = _deltas get "waypointAdvancesTotal";
                    _virtPhaseSamples = _deltas get "phaseSamplesTotal";
                    _virtPhaseSampleMs = _deltas get "phaseSampleMsTotal";
                    _virtPhaseProximityMs = _deltas get "phaseProximityMsTotal";
                    _virtPhaseScheduleMs = _deltas get "phaseScheduleMsTotal";
                    _virtPhaseAttachedMs = _deltas get "phaseAttachedMsTotal";
                    _virtPhaseMovementMs = _deltas get "phaseMovementMsTotal";
                    _virtPhasePositionUpdateMs = _deltas get "phasePositionUpdateMsTotal";
                    _virtPhaseCarrierSyncMs = _deltas get "phaseCarrierSyncMsTotal";
                    _virtPhaseActivationMs = _deltas get "phaseActivationMsTotal";
                    _virtPhaseActiveMs = _deltas get "phaseActiveMsTotal";
                    _virtPhaseAttachedHandled = _deltas get "phaseAttachedHandledTotal";
                    _virtPhaseMovementCalls = _deltas get "phaseMovementCallsTotal";
                    _virtPhasePositionUpdates = _deltas get "phasePositionUpdatesTotal";
                    _virtPhaseHoldingSkips = _deltas get "phaseHoldingSkipsTotal";
                    _virtPhaseActiveCalls = _deltas get "phaseActiveCallsTotal";
                };
                {
                    _lastStats set [_x, _virtStats get _x];
                } forEach keys _lastStats;
                FLO_PerformanceMonitorLastVirtSampleAt = _now;
            };

            if (isServer && {FLO_Debug_Level >= 5} && {_virtPhaseSamples > 0}) then {
                private _measuredPhaseMs = (
                    _virtPhaseProximityMs
                    + _virtPhaseScheduleMs
                    + _virtPhaseAttachedMs
                    + _virtPhaseMovementMs
                    + _virtPhaseActivationMs
                    + _virtPhaseActiveMs
                );
                private _residualMs = (_virtPhaseSampleMs - _measuredPhaseMs) max 0;
                diag_log format [
                    "[FLO][PERF] Virtualization phases window=%1s samples=%2 sampleTotal=%3ms residual=%4ms | proximity=%5 schedule=%6 attached=%7/%8 movement=%9/%10 holding=%11 position=%12/%13 carrier=%14 activation=%15 active=%16/%17",
                    round (_virtWindowSeconds * 10) / 10,
                    _virtPhaseSamples,
                    round (_virtPhaseSampleMs * 100) / 100,
                    round (_residualMs * 100) / 100,
                    round (_virtPhaseProximityMs * 100) / 100,
                    round (_virtPhaseScheduleMs * 100) / 100,
                    round (_virtPhaseAttachedMs * 100) / 100,
                    _virtPhaseAttachedHandled,
                    round (_virtPhaseMovementMs * 100) / 100,
                    _virtPhaseMovementCalls,
                    _virtPhaseHoldingSkips,
                    round (_virtPhasePositionUpdateMs * 100) / 100,
                    _virtPhasePositionUpdates,
                    round (_virtPhaseCarrierSyncMs * 100) / 100,
                    round (_virtPhaseActivationMs * 100) / 100,
                    round (_virtPhaseActiveMs * 100) / 100,
                    _virtPhaseActiveCalls
                ];
            };

            if (_fps >= 45 && {_fpsMin >= 30}) exitWith {};

            private _liveUnits = count allUnits;
            private _liveAi = { !isPlayer _x } count allUnits;
            private _liveGroups = count allGroups;
            private _liveVehicles = count vehicles;
            private _liveAgents = count agents;
            private _virtualGroups = "REMOTE";
            if (isServer) then {
                _virtualGroups = count (keys (call FLO_fnc_virtualizationGetGroupMap));
            };
            private _operationsOpen = hasInterface && {!isNull (findDisplay FLO_OperationsDialogIdd)};
            private _developmentOpen = hasInterface && {!isNull (findDisplay FLO_DevelopmentDialogIdd)};

            diag_log format [
                "[FLO][PERF][FRAME] fps=%1 min=%2 units=%3 ai=%4 groups=%5 vehicles=%6 agents=%7 virtual=%8 operationsOpen=%9 developmentOpen=%10 | virtWindow=%11s batches=%12 inspected=%13 due=%14 skipped=%15 moves=%16 activeSyncs=%17 waypointAdvances=%18 total=%19ms avgBatch=%20ms msPerSecond=%21",
                round (_fps * 10) / 10,
                round (_fpsMin * 10) / 10,
                _liveUnits,
                _liveAi,
                _liveGroups,
                _liveVehicles,
                _liveAgents,
                _virtualGroups,
                _operationsOpen,
                _developmentOpen,
                round (_virtWindowSeconds * 10) / 10,
                _virtBatches,
                _virtInspected,
                _virtDue,
                _virtSkipped,
                _virtMoves,
                _virtActiveSyncs,
                _virtWaypointAdvances,
                round (_virtBatchMs * 100) / 100,
                if (_virtBatches > 0) then { round ((_virtBatchMs / _virtBatches) * 100) / 100 } else { 0 },
                if (_virtWindowSeconds > 0) then { round ((_virtBatchMs / _virtWindowSeconds) * 100) / 100 } else { 0 }
            ];
        }, 10] call CBA_fnc_addPerFrameHandler;
    }
] call CBA_fnc_waitUntilAndExecute;
