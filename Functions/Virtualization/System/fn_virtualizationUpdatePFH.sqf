/*
 * Function: FLO_fnc_virtualizationUpdatePFH
 * Author: Frontline Operations Development Group
 * Description:
 *   Main virtualization update loop using CBA PerFrameHandler (unscheduled).
 *
 * Arguments:
 * 0: Mode <STRING> - "start", "stop", "restart", "stats", "resetstats"
 *
 * Return Value:
 * Boolean | HASHMAP
 */

params [["_mode", "start", [""]]];

#define BATCH_SIZE            25
#define PLAYER_CACHE_INTERVAL 1

[BATCH_SIZE, PLAYER_CACHE_INTERVAL] call FLO_fnc_virtualizationEnsureUpdateState;

switch (toLower _mode) do {
    case "start": {
        if (FLO_VirtUpdate get "running") exitWith {
            ["VIRTUALIZATION", 3, "Update PFH already running"] call FLO_fnc_log;
            true
        };

        private _pfhId = [{
            if !(FLO_virtualGroups get "_enabled") exitWith {};
            call FLO_fnc_virtualizationRunUpdateCycle;
        }, 0, []] call CBA_fnc_addPerFrameHandler;

        FLO_VirtUpdate set ["pfhId", _pfhId];
        FLO_VirtUpdate set ["running", true];
        FLO_VirtualGroupsUpdateLoopRunning = true;

        ["VIRTUALIZATION", 3, "Update PFH started (unscheduled)"] call FLO_fnc_log;
        true
    };

    case "stop": {
        private _pfhId = FLO_VirtUpdate get "pfhId";
        if (_pfhId >= 0) then {
            [_pfhId] call CBA_fnc_removePerFrameHandler;
            FLO_VirtUpdate set ["pfhId", -1];
        };

        FLO_VirtUpdate set ["running", false];
        FLO_VirtualGroupsUpdateLoopRunning = false;

        ["VIRTUALIZATION", 3, "Update PFH stopped"] call FLO_fnc_log;
        true
    };

    case "restart": {
        ["stop"] call FLO_fnc_virtualizationUpdatePFH;
        ["start"] call FLO_fnc_virtualizationUpdatePFH;
    };

    case "stats": {
        FLO_VirtUpdate get "stats"
    };

    case "resetstats": {
        call FLO_fnc_virtualizationResetUpdateStats;
    };

    default { false };
};
