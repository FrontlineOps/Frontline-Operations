/*
 * Function: FLO_fnc_virtualizationDebugManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Manages debug visualization for the virtualization system.
 *   Uses a separate PerFrameHandler to avoid blocking the main loop.
 *   Debug markers are updated asynchronously and won't affect performance.
 *
 * Arguments:
 * 0: Mode <STRING> - "init", "enable", "disable", "toggle", "cleanup"
 *
 * Return Value:
 * Boolean - Success
 *
 * Example:
 * ["init"] call FLO_fnc_virtualizationDebugManager;
 * ["toggle"] call FLO_fnc_virtualizationDebugManager;
 */

params [["_mode", "toggle", [""]]];

// Initialize debug state
FLO_VirtDebug = createHashMapFromArray [
    ["enabled", false],                  // Start disabled - must call "enable" to start
    ["pfhId", -1],
    ["markerNames", createHashMap],      // groupId -> markerName for O(1) cleanup
    ["wpMarkerNames", createHashMap],    // groupId -> [markerName1, markerName2, ...]
    ["updateInterval", 0.5],             // Seconds between marker updates
    ["lastUpdateTime", 0],
    ["batchSize", 20],                   // Groups to process per frame
    ["currentBatchIndex", 0]
];

// ============================================================================
// MODE HANDLERS
// ============================================================================

switch (toLower _mode) do {
    // ------------------------------------------------------------------------
    // INIT - Set up the debug system (called once at mission start)
    // ------------------------------------------------------------------------
    case "init": {
        ["VIRTUALIZATION_DEBUG", 3, "Debug manager initialized"] call FLO_fnc_log;
        true
    };

    // ------------------------------------------------------------------------
    // ENABLE - Start debug visualization
    // ------------------------------------------------------------------------
    case "enable": {
        if (FLO_VirtDebug get "enabled") exitWith {
            ["VIRTUALIZATION_DEBUG", 3, "Debug already enabled"] call FLO_fnc_log;
            true
        };

        FLO_VirtDebug set ["enabled", true];

        // Start the debug PFH (unscheduled, self-throttled)
        private _pfhId = [{
            params ["_args", "_pfhId"];

            // Exit if debug disabled
            if !(FLO_VirtDebug get "enabled") exitWith {};

            // Self-throttle: only update at configured interval
            private _now = diag_tickTime;
            private _lastUpdate = FLO_VirtDebug get "lastUpdateTime";
            private _interval = FLO_VirtDebug get "updateInterval";

            if (_now - _lastUpdate < _interval) exitWith {};

            FLO_VirtDebug set ["lastUpdateTime", _now];

            // Get groups to update
            private _groups = FLO_virtualGroups get "_groups";
            private _groupIds = keys _groups;
            private _totalGroups = count _groupIds;
            if (_totalGroups == 0) exitWith {};

            // Batch processing
            private _batchSize = FLO_VirtDebug get "batchSize";
            private _startIdx = FLO_VirtDebug get "currentBatchIndex";

            // Process batch
            for "_i" from _startIdx to ((_startIdx + _batchSize - 1) min (_totalGroups - 1)) do {
                private _groupId = _groupIds select _i;
                private _groupData = _groups get _groupId;

                [_groupId, _groupData] call FLO_fnc_virtualizationDebugUpdateMarker;
            };

            // Update batch index for next frame
            private _nextIdx = _startIdx + _batchSize;
            if (_nextIdx >= _totalGroups) then {
                FLO_VirtDebug set ["currentBatchIndex", 0];
            } else {
                FLO_VirtDebug set ["currentBatchIndex", _nextIdx];
            };

        }, 0, []] call CBA_fnc_addPerFrameHandler;

        FLO_VirtDebug set ["pfhId", _pfhId];

        // Set flag on main virtualization system for compatibility
        if (!isNil "FLO_virtualGroups") then {
            FLO_virtualGroups set ["_debugMode", true];
        };

        ["VIRTUALIZATION_DEBUG", 3, "Debug enabled - PFH started"] call FLO_fnc_log;
        true
    };

    // ------------------------------------------------------------------------
    // DISABLE - Stop debug visualization and clean up markers
    // ------------------------------------------------------------------------
    case "disable": {
        if !(FLO_VirtDebug get "enabled") exitWith {
            ["VIRTUALIZATION_DEBUG", 3, "Debug already disabled"] call FLO_fnc_log;
            true
        };

        FLO_VirtDebug set ["enabled", false];

        // Remove PFH
        private _pfhId = FLO_VirtDebug get "pfhId";
        if (_pfhId >= 0) then {
            [_pfhId] call CBA_fnc_removePerFrameHandler;
            FLO_VirtDebug set ["pfhId", -1];
        };

        // Clean up all markers using our tracked names (O(n) not O(n²))
        private _markerNames = FLO_VirtDebug get "markerNames";
        { deleteMarker _y; } forEach _markerNames;
        FLO_VirtDebug set ["markerNames", createHashMap];

        // Clean up waypoint markers
        private _wpMarkers = FLO_VirtDebug get "wpMarkerNames";
        {
            { deleteMarker _x; } forEach _y;
        } forEach _wpMarkers;
        FLO_VirtDebug set ["wpMarkerNames", createHashMap];

        // Update main virtualization system flag
        if (!isNil "FLO_virtualGroups") then {
            FLO_virtualGroups set ["_debugMode", false];
        };

        ["VIRTUALIZATION_DEBUG", 3, "Debug disabled - markers cleaned up"] call FLO_fnc_log;
        true
    };

    // ------------------------------------------------------------------------
    // TOGGLE - Switch debug state
    // ------------------------------------------------------------------------
    case "toggle": {
        if (FLO_VirtDebug get "enabled") then {
            ["disable"] call FLO_fnc_virtualizationDebugManager
        } else {
            ["enable"] call FLO_fnc_virtualizationDebugManager
        };
    };

    // ------------------------------------------------------------------------
    // CLEANUP - Remove a specific group's markers (called when group removed)
    // ------------------------------------------------------------------------
    case "cleanup": {
        // Called with additional param: groupId
        params ["", "_groupId"];

        private _markerNames = FLO_VirtDebug get "markerNames";
        private _markerName = _markerNames getOrDefault [_groupId, ""];
        if (_markerName != "") then {
            deleteMarker _markerName;
            _markerNames deleteAt _groupId;
        };

        private _wpMarkers = FLO_VirtDebug get "wpMarkerNames";
        private _wpList = _wpMarkers getOrDefault [_groupId, []];
        { deleteMarker _x; } forEach _wpList;
        _wpMarkers deleteAt _groupId;

        true
    };

    default {
        ["VIRTUALIZATION_DEBUG", 1, format["Unknown debug mode: %1", _mode]] call FLO_fnc_log;
        false
    };
};

