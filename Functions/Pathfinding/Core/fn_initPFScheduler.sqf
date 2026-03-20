XPS_typ_JobScheduler = [
    ["#type", "XPS_typ_JobScheduler"],
    ["#create", compileFinal {
        private _makeQueue = {
            createHashMapObject [[
                ["#type", "XPS_typ_Queue"],
                ["#str", compileFinal { _self get "#type" select 0 }],
                ["_queueArray", []],
                ["_head", 0],
                ["_count", 0],
                ["Clear", compileFinal {
                    (_self get "_queueArray") resize 0;
                    _self set ["_head", 0];
                    _self set ["_count", 0];
                }],
                ["Count", compileFinal {
                    _self get "_count";
                }],
                ["IsEmpty", compileFinal {
                    (_self get "_count") isEqualTo 0;
                }],
                ["Dequeue", compileFinal {
                    if (_self call ["IsEmpty"]) exitWith { nil };

                    private _arr = _self get "_queueArray";
                    private _head = _self get "_head";
                    private _item = _arr select _head;
                    private _newCount = (_self get "_count") - 1;

                    if (_newCount <= 0) exitWith {
                        _arr resize 0;
                        _self set ["_head", 0];
                        _self set ["_count", 0];
                        _item
                    };

                    _head = _head + 1;
                    _self set ["_head", _head];
                    _self set ["_count", _newCount];

                    if (_head > 256 && { (_head * 2) > (count _arr) }) then {
                        private _compact = _arr select [_head, (count _arr) - _head];
                        _self set ["_queueArray", _compact];
                        _self set ["_head", 0];
                    };

                    _item
                }],
                ["Enqueue", compileFinal {
                    (_self get "_queueArray") pushBack _this;
                    _self set ["_count", (_self get "_count") + 1];
                }]
            ]]
        };

        _self set ["_queueObject", call _makeQueue];
        _self set ["_metrics", createHashMapFromArray [
            ["submitted", 0],
            ["completedSuccess", 0],
            ["completedPartial", 0],
            ["nodeSteps", 0],
            ["resolvedCount", 0],
            ["resolvedNodeStepsLast", 0],
            ["resolvedNodeStepsPeak", 0],
            ["resolvedNodeStepsTotal", 0],
            ["resolvedMsLast", 0],
            ["resolvedMsPeak", 0],
            ["resolvedMsTotal", 0],
            ["emittedWaypointsLast", 0],
            ["emittedWaypointsPeak", 0],
            ["emittedWaypointsTotal", 0],
            ["processedThisFrame", 0],
            ["queueDepth", 0],
            ["queuePeak", 0],
            ["frameCostMs", 0],
            ["lastNonZeroFrameCostMs", 0],
            ["frameCostPeakMs", 0],
            ["hadWorkLastFrame", false],
            ["lastFrameAt", 0],
            ["lastWorkFrameAt", 0]
        ]];
    }],
    ["_handle", -1],
    ["_queueObject", nil],
    ["_metrics", nil],
    ["CurrentItem", nil],
    ["MaxNodesPerFrame", 32],
    ["hasSearchWork", compileFinal {
        if !(isNil { _self get "CurrentItem" }) exitWith { true };
        !((_self get "_queueObject") call ["IsEmpty"]);
    }],
    ["dequeue", compileFinal {
        private _next = (_self get "_queueObject") call ["Dequeue"];
        if (isNil { _next }) then {
            _self set ["CurrentItem", nil];
        } else {
            _self set ["CurrentItem", _next];
        };
    }],
    ["finalizeCurrent", compileFinal {
        private _item = _self get "CurrentItem";
        private _status = _item get "Status";
        private _resolvedPath = _item call ["SmoothPath"];
        private _resolvedWaypointCount = count _resolvedPath;
        private _resolvedNodeSteps = _item get "NodeSteps";
        private _resolvedMs = if (isNil { _item get "SubmittedAt" }) then {
            0
        } else {
            (diag_tickTime - (_item get "SubmittedAt")) * 1000
        };
        _item call ["Callback", [count _resolvedPath > 0, _resolvedPath, _item get "CallbackArgs"]];

        private _metrics = _self get "_metrics";
        if (_status isEqualTo "SUCCESS") then {
            _metrics set ["completedSuccess", (_metrics get "completedSuccess") + 1];
        } else {
            _metrics set ["completedPartial", (_metrics get "completedPartial") + 1];
        };
        _metrics set ["resolvedCount", (_metrics get "resolvedCount") + 1];
        _metrics set ["resolvedNodeStepsLast", _resolvedNodeSteps];
        _metrics set ["resolvedNodeStepsTotal", (_metrics get "resolvedNodeStepsTotal") + _resolvedNodeSteps];
        _metrics set ["resolvedMsLast", _resolvedMs];
        _metrics set ["resolvedMsTotal", (_metrics get "resolvedMsTotal") + _resolvedMs];
        _metrics set ["emittedWaypointsLast", _resolvedWaypointCount];
        _metrics set ["emittedWaypointsTotal", (_metrics get "emittedWaypointsTotal") + _resolvedWaypointCount];
        if (_resolvedNodeSteps > (_metrics get "resolvedNodeStepsPeak")) then {
            _metrics set ["resolvedNodeStepsPeak", _resolvedNodeSteps];
        };
        if (_resolvedMs > (_metrics get "resolvedMsPeak")) then {
            _metrics set ["resolvedMsPeak", _resolvedMs];
        };
        if (_resolvedWaypointCount > (_metrics get "emittedWaypointsPeak")) then {
            _metrics set ["emittedWaypointsPeak", _resolvedWaypointCount];
        };

        private _sourceTag = _item get "SourceTag";
        private _sourceStats = FLO_PF_SourceStats;
        private _completedSuccessBySource = _sourceStats get "completedSuccess";
        private _completedPartialBySource = _sourceStats get "completedPartial";
        private _resolvedCountBySource = _sourceStats get "resolvedCount";
        private _resolvedNodeStepsLastBySource = _sourceStats get "resolvedNodeStepsLast";
        private _resolvedNodeStepsTotalBySource = _sourceStats get "resolvedNodeStepsTotal";
        private _resolvedNodeStepsPeakBySource = _sourceStats get "resolvedNodeStepsPeak";
        private _resolvedMsLastBySource = _sourceStats get "resolvedMsLast";
        private _resolvedMsTotalBySource = _sourceStats get "resolvedMsTotal";
        private _resolvedMsPeakBySource = _sourceStats get "resolvedMsPeak";
        private _emittedLastBySource = _sourceStats get "emittedWaypointsLast";
        private _emittedTotalBySource = _sourceStats get "emittedWaypointsTotal";
        private _emittedPeakBySource = _sourceStats get "emittedWaypointsPeak";
        private _inFlightBySource = _sourceStats get "inFlight";

        if (_status isEqualTo "SUCCESS") then {
            _completedSuccessBySource set [_sourceTag, (_completedSuccessBySource getOrDefault [_sourceTag, 0]) + 1];
        } else {
            _completedPartialBySource set [_sourceTag, (_completedPartialBySource getOrDefault [_sourceTag, 0]) + 1];
        };

        _resolvedCountBySource set [_sourceTag, (_resolvedCountBySource getOrDefault [_sourceTag, 0]) + 1];
        _resolvedNodeStepsLastBySource set [_sourceTag, _resolvedNodeSteps];
        _resolvedNodeStepsTotalBySource set [_sourceTag, (_resolvedNodeStepsTotalBySource getOrDefault [_sourceTag, 0]) + _resolvedNodeSteps];
        if (_resolvedNodeSteps > (_resolvedNodeStepsPeakBySource getOrDefault [_sourceTag, 0])) then {
            _resolvedNodeStepsPeakBySource set [_sourceTag, _resolvedNodeSteps];
        };
        _resolvedMsLastBySource set [_sourceTag, _resolvedMs];
        _resolvedMsTotalBySource set [_sourceTag, (_resolvedMsTotalBySource getOrDefault [_sourceTag, 0]) + _resolvedMs];
        if (_resolvedMs > (_resolvedMsPeakBySource getOrDefault [_sourceTag, 0])) then {
            _resolvedMsPeakBySource set [_sourceTag, _resolvedMs];
        };

        _emittedLastBySource set [_sourceTag, _resolvedWaypointCount];
        _emittedTotalBySource set [_sourceTag, (_emittedTotalBySource getOrDefault [_sourceTag, 0]) + _resolvedWaypointCount];
        if (_resolvedWaypointCount > (_emittedPeakBySource getOrDefault [_sourceTag, 0])) then {
            _emittedPeakBySource set [_sourceTag, _resolvedWaypointCount];
        };

        private _remainingInFlight = (_inFlightBySource getOrDefault [_sourceTag, 0]) - 1;
        if (_remainingInFlight < 0) then {
            _remainingInFlight = 0;
        };
        _inFlightBySource set [_sourceTag, _remainingInFlight];

        private _perf = FLO_PF_Perf;
        private _now = diag_tickTime;
        if (_resolvedMs >= (_perf get "slowSearchThresholdMs") && { _now >= (_perf get "nextSlowSearchLogAt") }) then {
            _perf set ["nextSlowSearchLogAt", _now + (_perf get "logCooldownSec")];
            diag_log format [
                "[FLO][PERF] Pathfinding route source=%1 status=%2 distance=%3 m waypoints=%4 nodes=%5 resolved in %6 ms",
                _item get "SourceTag",
                _status,
                _item get "RequestDistance",
                _resolvedWaypointCount,
                _resolvedNodeSteps,
                _resolvedMs
            ];
        };

        _self call ["dequeue"];
    }],
    ["preprocessCurrent", compileFinal {
        if (isNil { _self get "CurrentItem" }) then {
            _self call ["dequeue"];
        };

        if !(isNil { _self get "CurrentItem" }) then {
            private _item = _self get "CurrentItem";
            private _metrics = _self get "_metrics";
            _metrics set ["nodeSteps", (_metrics get "nodeSteps") + 1];
            _item set ["NodeSteps", (_item get "NodeSteps") + 1];

            private _done = _item call ["ProcessNextNode"];
            if (_done) then {
                _self call ["finalizeCurrent"];
            };
        };
    }],
    ["AddItem", compileFinal {
        if !(_this isEqualType createHashMap) exitWith { false };

        (_self get "_queueObject") call ["Enqueue", _this];
        private _metrics = _self get "_metrics";
        _metrics set ["submitted", (_metrics get "submitted") + 1];

        private _depth = (_self get "_queueObject") call ["Count"];
        _metrics set ["queueDepth", _depth];
        if (_depth > (_metrics get "queuePeak")) then {
            _metrics set ["queuePeak", _depth];
        };

        true;
    }],
    ["GetMetrics", compileFinal {
        _self get "_metrics";
    }],
    ["Start", compileFinal {
        private _handle = _self get "_handle";
        if (_handle >= 0) exitWith {
            _self call ["Stop"];
            _self call ["Start"];
        };

        _handle = [{
            params ["_args", "_pfhId"];
            private _sched = _args # 0;
            private _frameStart = diag_tickTime;
            private _count = 0;
            private _limit = _sched get "MaxNodesPerFrame";

            while { _count < _limit } do {
                if !(_sched call ["hasSearchWork"]) exitWith {};
                _sched call ["preprocessCurrent"];
                _count = _count + 1;
            };

            private _metrics = _sched get "_metrics";
            private _queueDepth = ((_sched get "_queueObject") call ["Count"]);
            private _frameCost = (diag_tickTime - _frameStart) * 1000;

            _metrics set ["processedThisFrame", _count];
            _metrics set ["queueDepth", _queueDepth];
            _metrics set ["frameCostMs", _frameCost];
            _metrics set ["hadWorkLastFrame", _count > 0];

            if (_queueDepth > (_metrics get "queuePeak")) then {
                _metrics set ["queuePeak", _queueDepth];
            };
            if (_count > 0) then {
                _metrics set ["lastWorkFrameAt", diag_tickTime];
                _metrics set ["lastNonZeroFrameCostMs", _frameCost];
            };
            if (_frameCost > (_metrics get "frameCostPeakMs")) then {
                _metrics set ["frameCostPeakMs", _frameCost];
            };

            private _perf = FLO_PF_Perf;
            private _now = diag_tickTime;
            if (_frameCost >= (_perf get "slowFrameThresholdMs") && { _now >= (_perf get "nextSlowFrameLogAt") }) then {
                _perf set ["nextSlowFrameLogAt", _now + (_perf get "logCooldownSec")];
                diag_log format [
                    "[FLO][PERF] Pathfinding scheduler processed %1 nodes with queue=%2 in %3 ms (cap=%4)",
                    _count,
                    _queueDepth,
                    _frameCost,
                    _limit
                ];
            };

            _metrics set ["lastFrameAt", diag_tickTime];
        }, 0, [_self]] call CBA_fnc_addPerFrameHandler;

        _self set ["_handle", _handle];
    }],
    ["Stop", compileFinal {
        private _handle = _self get "_handle";
        if (_handle >= 0) then {
            [_handle] call CBA_fnc_removePerFrameHandler;
            _self set ["_handle", -1];
        };
    }]
];

if (isNil "FLO_PF_Scheduler") then {
    FLO_PF_Scheduler = createHashMapObject [XPS_typ_JobScheduler];
    FLO_PF_Scheduler call ["Start"];
};
