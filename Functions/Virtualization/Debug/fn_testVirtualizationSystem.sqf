/*
 * Function: FLO_fnc_testVirtualizationSystem
 * Author: Frontline Operations Development Group
 * Description:
 *   Comprehensive test of the virtualization system.
 *   Tests all major components: PFH, spatial index, events, debug system.
 *
 * Arguments:
 * 0: Mode <STRING> - "full", "quick", "pfh", "spatial", "events", "debug"
 *
 * Return Value:
 * HashMap with test results
 *
 * Example (Debug Console):
 * ["full"] call FLO_fnc_testVirtualizationSystem;
 * ["quick"] call FLO_fnc_testVirtualizationSystem;
 */

params [["_mode", "quick", [""]]];

private _results = createHashMapFromArray [
    ["passed", 0],
    ["failed", 0],
    ["tests", []]
];

private _addResult = {
    params ["_name", "_passed", "_message"];
    private _tests = _results get "tests";
    _tests pushBack [_name, _passed, _message];
    if (_passed) then {
        _results set ["passed", (_results get "passed") + 1];
    } else {
        _results set ["failed", (_results get "failed") + 1];
    };
    systemChat format ["%1: %2 - %3", if (_passed) then {"PASS"} else {"FAIL"}, _name, _message];
};

// ============================================================================
// QUICK TESTS - Basic system checks
// ============================================================================
if (_mode in ["quick", "full"]) then {
    systemChat "=== VIRTUALIZATION SYSTEM TESTS ===";
    
    // Test 1: System initialized
    private _sysInit = !isNil "FLO_virtualGroups" && !isNil "FLO_VirtualizationReady";
    ["System Initialized", _sysInit, if (_sysInit) then {"OK"} else {"FLO_virtualGroups not found"}] call _addResult;
    
    // Test 2: PFH running
    private _pfhRunning = !isNil "FLO_VirtUpdate" && {FLO_VirtUpdate get "running"};
    ["PFH Running", _pfhRunning, if (_pfhRunning) then {"OK"} else {"PFH not running"}] call _addResult;
    
    // Test 3: Spatial index exists
    private _spatialInit = !isNil "FLO_VirtSpatial";
    ["Spatial Index", _spatialInit, if (_spatialInit) then {"OK"} else {"Not initialized"}] call _addResult;
    
    // Test 4: Debug manager exists
    private _debugInit = !isNil "FLO_VirtDebug";
    ["Debug Manager", _debugInit, if (_debugInit) then {"OK"} else {"Not initialized"}] call _addResult;
    
    // Test 5: Event handlers registered
    private _eventsInit = !isNil "FLO_VirtEventHandlers" && {count keys FLO_VirtEventHandlers > 0};
    ["Event Handlers", _eventsInit, if (_eventsInit) then {format["%1 handlers", count keys FLO_VirtEventHandlers]} else {"Not registered"}] call _addResult;
};

// ============================================================================
// PFH TESTS - Update loop functionality
// ============================================================================
if (_mode in ["pfh", "full"]) then {
    systemChat "--- PFH Tests ---";
    
    // Test PFH stats
    if (!isNil "FLO_VirtUpdate") then {
        private _stats = ["stats"] call FLO_fnc_virtualizationUpdatePFH;
        private _hasStats = !isNil "_stats" && {_stats isEqualType createHashMap};
        ["PFH Stats", _hasStats, if (_hasStats) then {format["Cycles: %1", _stats getOrDefault ["cycles", 0]]} else {"No stats"}] call _addResult;
    };
};

// ============================================================================
// SPATIAL INDEX TESTS
// ============================================================================
if (_mode in ["spatial", "full"]) then {
    systemChat "--- Spatial Index Tests ---";
    
    // Test add/query
    private _testPos = [15000, 15000, 0];
    ["add", ["test_spatial_1", _testPos]] call FLO_fnc_virtualizationSpatialIndex;
    private _queryResult = ["query", [_testPos]] call FLO_fnc_virtualizationSpatialIndex;
    private _addWorks = "test_spatial_1" in _queryResult;
    ["Spatial Add/Query", _addWorks, if (_addWorks) then {"OK"} else {"Query failed"}] call _addResult;
    
    // Test radius query
    private _radiusResult = ["queryradius", [_testPos, 1000]] call FLO_fnc_virtualizationSpatialIndex;
    private _radiusWorks = "test_spatial_1" in _radiusResult;
    ["Spatial Radius Query", _radiusWorks, if (_radiusWorks) then {"OK"} else {"Radius query failed"}] call _addResult;
    
    // Cleanup
    ["remove", ["test_spatial_1"]] call FLO_fnc_virtualizationSpatialIndex;
};

// ============================================================================
// DEBUG SYSTEM TESTS
// ============================================================================
if (_mode in ["debug", "full"]) then {
    systemChat "--- Debug System Tests ---";
    
    // Test toggle on
    ["enable"] call FLO_fnc_virtualizationDebugManager;
    sleep 0.1;
    private _debugOn = FLO_VirtDebug get "enabled";
    ["Debug Enable", _debugOn, if (_debugOn) then {"OK"} else {"Failed to enable"}] call _addResult;
    
    // Test toggle off
    ["disable"] call FLO_fnc_virtualizationDebugManager;
    sleep 0.1;
    private _debugOff = !(FLO_VirtDebug get "enabled");
    ["Debug Disable", _debugOff, if (_debugOff) then {"OK"} else {"Failed to disable"}] call _addResult;
};

// ============================================================================
// SUMMARY
// ============================================================================
systemChat "=== TEST SUMMARY ===";
systemChat format ["Passed: %1 / Failed: %2", _results get "passed", _results get "failed"];

if ((_results get "failed") > 0) then {
    systemChat "FAILED TESTS:";
    {
        _x params ["_name", "_passed", "_msg"];
        if (!_passed) then {
            systemChat format ["  - %1: %2", _name, _msg];
        };
    } forEach (_results get "tests");
};

_results

