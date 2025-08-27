/*
 * Function: FLO_fnc_missionQueue
 * Author: Frontline Operations Development Group
 * Description:
 *   Maintains a small queue of active side missions to keep players engaged.
 *   - Tries to keep at least N missions available
 *   - Avoids spawning multiple convoy missions at once
 *   - Applies per-mission-type cooldowns to prevent spam/repeats
 *
 * Notes:
 *   Side missions are registered in FLO_registeredSideMissions.
 *   Many mission functions spawn their own logic and do not return a handle.
 *   We therefore track "recently started" missions with TTL and cooldowns.
 */

if (!isServer) exitWith {};

// Respect startup grace period
private _missionStartTime = missionNamespace getVariable ["FLO_missionStartTime", 0];
private _gracePeriod = 600; // 10 minutes
if (_missionStartTime > 0 && {diag_tickTime - _missionStartTime < _gracePeriod}) exitWith {
    ["QUEUE", 2, format ["Mission queue waiting for grace period (%1s remaining)", _gracePeriod - (diag_tickTime - _missionStartTime)]] call FLO_fnc_log;
};

private _desiredActive = 2;              // Target number of concurrent missions
private _recentTTL = 15 * 60;            // Consider missions "active/recent" for 15 minutes
private _perTypeCooldown = 10 * 60;      // Minimum time before the same mission can be started again
private _tickSleepMin = 60;              // Min delay between queue checks
private _tickSleepMax = 120;             // Max delay between queue checks
private _convoyTypes = ["convoyInterdiction", "customConvoy"]; // Mutually exclusive

// Initialize state containers if missing
if (isNil "FLO_recentMissions") then { FLO_recentMissions = []; publicVariable "FLO_recentMissions"; };
if (isNil "FLO_missionCooldowns") then { FLO_missionCooldowns = createHashMap; publicVariable "FLO_missionCooldowns"; };

// Main loop
[] spawn {
    if (!isServer) exitWith {};

    // Configuration (local to spawned thread)
    private _desiredActive = 2;
    private _recentTTL = 15 * 60;
    private _perTypeCooldown = 10 * 60;
    private _tickSleepMin = 60;
    private _tickSleepMax = 120;
    private _convoyTypes = ["convoyInterdiction", "customConvoy"];

    // Ensure state containers
    if (isNil "FLO_recentMissions") then { FLO_recentMissions = []; publicVariable "FLO_recentMissions"; };
    if (isNil "FLO_missionCooldowns") then { FLO_missionCooldowns = createHashMap; publicVariable "FLO_missionCooldowns"; };

    // Helpers defined inside the spawned scope
    private _prune = {
        private _now = time;
        private _filtered = [];
        {
            _x params ["_name", "_startTime"];
            if ((_now - _startTime) < _recentTTL) then { _filtered pushBack _x; };
        } forEach FLO_recentMissions;
        FLO_recentMissions = _filtered;
        publicVariable "FLO_recentMissions";
    };

    private _canStart = {
        params ["_name"];

        if (_name in _convoyTypes) then {
            if (!isNil "ConVLocc" && {ConVLocc > 0}) exitWith {false};
            if ((FLO_recentMissions findIf { (_x select 0) in _convoyTypes }) > -1) exitWith {false};
        };

        private _now = time;
        private _until = FLO_missionCooldowns getOrDefault [_name, 0];
        if (_now < _until) exitWith {false};

        if ((FLO_recentMissions findIf { (_x select 0) == _name }) > -1) exitWith {false};
        true
    };

    private _markStarted = {
        params ["_name"];
        FLO_recentMissions pushBack [_name, time];
        publicVariable "FLO_recentMissions";
        FLO_missionCooldowns set [_name, time + _perTypeCooldown];
        publicVariable "FLO_missionCooldowns";
    };

    // small randomized start delay
    sleep (5 + random 5);

    while {true} do {
        // Ensure registrations exist; if not, wait and retry
        if (isNil "FLO_registeredSideMissions") then { sleep 5; continue; };

        // Respect startup grace period
        private _missionStartTime = missionNamespace getVariable ["FLO_missionStartTime", 0];
        private _gracePeriod = 600; // 10 minutes
        if (_missionStartTime > 0 && {diag_tickTime - _missionStartTime < _gracePeriod}) then {
            sleep 10;
            continue;
        };

        // Prune old entries
        call _prune;

        // Determine how many new missions we need
        private _currentCount = count FLO_recentMissions;
        if (_currentCount >= _desiredActive) exitWith {};
        private _missing = _desiredActive - _currentCount;

        if (_missing > 0) then {
            private _names = keys FLO_registeredSideMissions;
            _names = _names call BIS_fnc_arrayShuffle;

            {
                if (_x call _canStart) then {
                    private _ok = true;
                    if ((_x in _convoyTypes) && {!isNil "ConVLocc" && {ConVLocc > 0}}) then { _ok = false; };

                    if (_ok) then {
                        [_x] call FLO_fnc_startSideMission;
                        [_x] call _markStarted;
                        ["STR_FLO_INTEL_TITLE", format ["New mission available: %1", _x], "intel"] call FLO_fnc_sendNotification;
                        _missing = _missing - 1;
                        if (_missing <= 0) exitWith {};
                    };
                };
            } forEach _names;
        };

        sleep (_tickSleepMin + random (_tickSleepMax - _tickSleepMin));
    };
};
