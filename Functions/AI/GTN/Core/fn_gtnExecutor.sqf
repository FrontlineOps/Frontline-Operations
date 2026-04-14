/*
 * Function: FLO_fnc_gtnExecutor
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Goal Task Network plan executor for the current frontline allocation model.
 * The live executor only needs to bridge two primitives:
 * - prim_allocate_frontline_attacks
 * - prim_allocate_frontline_defense
 *
 * Arguments:
 * 0: Commander Host <HASHMAP> - Commander host object
 * 1: Side Context <HASHMAP> - Normalized own/enemy side context
 *
 * Return Value:
 * Executor HashMap Object <HASHMAP>
 *
 * Example:
 * private _executor = [_commander, [east] call FLO_fnc_gtnSideContext] call FLO_fnc_gtnExecutor;
 * _executor call ["_executePrimitive", [_taskNode]];
 */

params [
    ["_commander", nil],
    ["_sideContext", createHashMap]
];

if (isNil "_commander") exitWith {
    ["GTN", 1, "Executor requires commander reference"] call FLO_fnc_log;
    nil
};

if (isNil "_sideContext" || {!(_sideContext isEqualType createHashMap)} || {count _sideContext == 0}) then {
    _sideContext = [east] call FLO_fnc_gtnSideContext;
};

private _ownSide = _sideContext get "ownSide";
private _enemySide = _sideContext get "enemySide";
private _sideKey = _sideContext get "sideKey";

["GTN", 3, format ["Initializing GTN Executor (%1)", _sideKey]] call FLO_fnc_log;

private _executor = createHashMapObject [[
    ["_aiCommander", _commander],
    ["_sideContext", _sideContext],
    ["_ownSide", _ownSide],
    ["_enemySide", _enemySide],
    ["_sideKey", _sideKey],
    ["_gtnCommander", nil],
    ["_activeExecutions", createHashMap],
    ["_handlers", createHashMap],
    ["_activeTrackId", "GLOBAL"],
    ["_perf", createHashMapFromArray [
        ["primitiveLogThresholdMs", 10],
        ["checkLogThresholdMs", 10],
        ["lastPrimitiveMs", createHashMap],
        ["peakPrimitiveMs", createHashMap],
        ["slowPrimitiveCount", createHashMap],
        ["lastCheckMs", createHashMap],
        ["peakCheckMs", createHashMap],
        ["slowCheckCount", createHashMap]
    ]],

    ["_setGTNCommander", {
        params ["_gtnCmdr"];
        _self set ["_gtnCommander", _gtnCmdr];
    }],

    ["_registerHandler", {
        params ["_primitiveId", "_handlerFn"];
        private _handlers = _self get "_handlers";
        _handlers set [_primitiveId, _handlerFn];
        _self set ["_handlers", _handlers];
    }],

    ["_getPerf", {
        _self get "_perf"
    }],

    ["_resolveTrackId", {
        params [["_taskNode", nil]];

        if (isNil "_taskNode") exitWith { _self get "_activeTrackId" };
        if !(_taskNode isEqualType createHashMap) exitWith { _self get "_activeTrackId" };

        private _track = _taskNode getOrDefault ["_trackRef", nil];
        if (isNil "_track") exitWith { _self get "_activeTrackId" };
        if !(_track isEqualType createHashMap) exitWith { _self get "_activeTrackId" };

        _track getOrDefault ["id", _self get "_activeTrackId"]
    }],

    ["_setActiveTrack", {
        params [["_taskNode", nil]];
        private _trackId = _self call ["_resolveTrackId", [_taskNode]];
        _self set ["_activeTrackId", _trackId];
        _trackId
    }],

    ["_getExecutionKey", {
        params ["_taskRef"];

        private _taskNode = if (_taskRef isEqualType createHashMap) then { _taskRef } else { nil };
        private _taskId = if (!isNil "_taskNode") then { _taskNode get "taskId" } else { _taskRef };
        private _trackId = if (!isNil "_taskNode") then {
            _self call ["_resolveTrackId", [_taskNode]]
        } else {
            _self get "_activeTrackId"
        };

        format ["%1::%2", _trackId, _taskId]
    }],

    ["_executePrimitive", {
        params ["_taskNode"];

        private _trackId = _self call ["_setActiveTrack", [_taskNode]];
        private _taskId = _taskNode get "taskId";
        private _params = _taskNode get "params";
        private _executionKey = format ["%1::%2", _trackId, _taskId];

        private _handlers = _self get "_handlers";
        private _handler = _handlers getOrDefault [_taskId, nil];
        if (isNil "_handler") exitWith {
            ["GTN", 2, format ["No handler registered for primitive: %1", _taskId]] call FLO_fnc_log;
            false
        };

        ["GTN", 3, format [">>> EXECUTING PRIMITIVE: %1 with params: %2", _taskId, _params]] call FLO_fnc_log;

        private _context = createHashMapFromArray [
            ["commander", _self get "_gtnCommander"],
            ["aiCommander", _self get "_aiCommander"],
            ["executor", _self],
            ["taskNode", _taskNode],
            ["trackId", _trackId],
            ["executionKey", _executionKey],
            ["params", _params],
            ["startTime", diag_tickTime],
            ["status", "RUNNING"]
        ];

        private _tExec = diag_tickTime;
        private _result = [_context] call _handler;
        private _execMs = (diag_tickTime - _tExec) * 1000;

        private _perf = _self get "_perf";
        private _lastPrimitiveMs = _perf get "lastPrimitiveMs";
        private _peakPrimitiveMs = _perf get "peakPrimitiveMs";
        private _slowPrimitiveCount = _perf get "slowPrimitiveCount";
        _lastPrimitiveMs set [_taskId, _execMs];
        private _peakPrimitive = _peakPrimitiveMs get _taskId;
        if (isNil "_peakPrimitive" || {_execMs > _peakPrimitive}) then {
            _peakPrimitiveMs set [_taskId, _execMs];
        };
        if (_execMs >= (_perf get "primitiveLogThresholdMs")) then {
            _slowPrimitiveCount set [_taskId, (_slowPrimitiveCount getOrDefault [_taskId, 0]) + 1];
            diag_log format [
                "[FLO][PERF] GTN executor %1 primitive %2 track=%3 execute took %4 ms",
                _self get "_sideKey",
                _taskId,
                _trackId,
                _execMs
            ];
        };

        private _active = _self get "_activeExecutions";
        _active set [_executionKey, _context];

        _result
    }],

    ["_checkExecution", {
        params ["_taskRef"];

        private _taskNode = if (_taskRef isEqualType createHashMap) then { _taskRef } else { nil };
        private _taskId = if (!isNil "_taskNode") then { _taskNode get "taskId" } else { _taskRef };

        if (!isNil "_taskNode") then {
            _self call ["_setActiveTrack", [_taskNode]];
        };

        private _executionKey = _self call ["_getExecutionKey", [_taskRef]];
        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_executionKey, nil];
        if (isNil "_context") exitWith { "UNKNOWN" };

        private _status = _context get "status";
        if (_status == "RUNNING") then {
            private _handlers = _self get "_handlers";
            private _handler = _handlers getOrDefault [_taskId, nil];

            if (!isNil "_handler") then {
                private _tCheck = diag_tickTime;
                [_context] call _handler;
                private _checkMs = (diag_tickTime - _tCheck) * 1000;

                private _perf = _self get "_perf";
                private _lastCheckMs = _perf get "lastCheckMs";
                private _peakCheckMs = _perf get "peakCheckMs";
                private _slowCheckCount = _perf get "slowCheckCount";
                _lastCheckMs set [_taskId, _checkMs];
                private _peakCheck = _peakCheckMs get _taskId;
                if (isNil "_peakCheck" || {_checkMs > _peakCheck}) then {
                    _peakCheckMs set [_taskId, _checkMs];
                };
                if (_checkMs >= (_perf get "checkLogThresholdMs")) then {
                    _slowCheckCount set [_taskId, (_slowCheckCount getOrDefault [_taskId, 0]) + 1];
                    diag_log format [
                        "[FLO][PERF] GTN executor %1 primitive %2 check took %3 ms",
                        _self get "_sideKey",
                        _taskId,
                        _checkMs
                    ];
                };

                _status = _context get "status";
            };
        };

        _status
    }],

    ["_updateExecution", {
        params ["_taskRef", "_key", "_value"];
        private _executionKey = _self call ["_getExecutionKey", [_taskRef]];
        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_executionKey, nil];

        if (!isNil "_context") then {
            _context set [_key, _value];
        };
    }],

    ["_completeExecution", {
        params ["_taskRef", ["_success", true]];
        private _executionKey = _self call ["_getExecutionKey", [_taskRef]];
        private _active = _self get "_activeExecutions";
        private _context = _active getOrDefault [_executionKey, nil];

        if (!isNil "_context") then {
            _context set ["status", if (_success) then { "SUCCESS" } else { "FAILED" }];
            _context set ["endTime", diag_tickTime];
        };
    }],

    ["_initialize", {
        _self call ["_registerHandlers", []];
        ["GTN", 3, "Executor handlers registered"] call FLO_fnc_log;
    }],

    ["_registerHandlers", {
        _self call ["_registerHandler", ["prim_allocate_frontline_attacks", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            if (isNil "_track") exitWith {
                _ctx set ["status", "FAILED"];
                false
            };

            private _metrics = _cmdr call ["_allocateFrontlineAttacks", [_track]];
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["metrics", _metrics];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];

        _self call ["_registerHandler", ["prim_allocate_frontline_defense", {
            params ["_ctx"];
            private _cmdr = _ctx get "commander";
            private _taskNode = _ctx get "taskNode";
            private _track = _taskNode get "_trackRef";
            if (isNil "_track") exitWith {
                _ctx set ["status", "FAILED"];
                false
            };

            private _metrics = _cmdr call ["_allocateFrontlineDefense", [_track]];
            private _primData = _taskNode getOrDefault ["primitiveData", createHashMap];
            _primData set ["metrics", _metrics];
            _taskNode set ["primitiveData", _primData];

            _ctx set ["status", "SUCCESS"];
            true
        }]];
    }]
]];

_executor call ["_initialize", []];

["GTN", 3, "GTN Executor initialized"] call FLO_fnc_log;

_executor
