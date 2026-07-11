/*
 * Function: FLO_fnc_netDebugDump
 * Author: Frontline Operations Development Group
 * Description:
 *   Emits one summarized network-debug line to the RPT and optionally hints it
 *   to connected players for live investigation.
 *
 * Arguments:
 *   0: Broadcast summary via hintSilent <BOOL>
 *
 * Return Value:
 *   Snapshot <HASHMAP>
 */

if (!isServer) exitWith { createHashMap };

params [
    ["_broadcast", false, [true]]
];

private _snapshot = call FLO_fnc_netDebugSnapshot;
private _counters = _snapshot get "counters";
private _windowAge = _snapshot get "windowAgeSeconds";
private _windowAgeRounded = if (_windowAge >= 0) then { round _windowAge } else { 0 };

private _summary = format [
    "[FLO][NET] %1s window | intel=%2 markers=%3 intelTargets=%4 | alertFlush=%5 alertMarkers=%6 alertTargets=%7 | cmdRadio=%8 cmdRadioTargets=%9 | artyRadio=%10 artyLines=%11 artyTargets=%12 | dynText=%13 | idsVis=%14 | players=%15 ai=%16 groups=%17 vehicles=%18 dead=%19 markers=%20 virtual=%21 fps=%22",
    _windowAgeRounded,
    if ("commanderIntelPublishes" in _counters) then { _counters get "commanderIntelPublishes" } else { 0 },
    if ("commanderIntelMarkers" in _counters) then { _counters get "commanderIntelMarkers" } else { 0 },
    if ("commanderIntelTargets" in _counters) then { _counters get "commanderIntelTargets" } else { 0 },
    if ("alertFlushes" in _counters) then { _counters get "alertFlushes" } else { 0 },
    if ("alertMarkers" in _counters) then { _counters get "alertMarkers" } else { 0 },
    if ("alertTargets" in _counters) then { _counters get "alertTargets" } else { 0 },
    if ("commanderRadioMessages" in _counters) then { _counters get "commanderRadioMessages" } else { 0 },
    if ("commanderRadioTargets" in _counters) then { _counters get "commanderRadioTargets" } else { 0 },
    if ("artilleryRadioMissions" in _counters) then { _counters get "artilleryRadioMissions" } else { 0 },
    if ("artilleryRadioLines" in _counters) then { _counters get "artilleryRadioLines" } else { 0 },
    if ("artilleryRadioTargets" in _counters) then { _counters get "artilleryRadioTargets" } else { 0 },
    if ("dynamicTextBroadcasts" in _counters) then { _counters get "dynamicTextBroadcasts" } else { 0 },
    if ("idsVisibilityToggles" in _counters) then { _counters get "idsVisibilityToggles" } else { 0 },
    _snapshot get "players",
    _snapshot get "aiUnits",
    _snapshot get "groups",
    _snapshot get "vehicles",
    _snapshot get "deadAll",
    _snapshot get "markers",
    _snapshot get "virtualGroups",
    round (_snapshot get "serverFps")
];

diag_log _summary;

if (_broadcast) then {
    [_summary] remoteExec ["hintSilent", 0, false];
};

FLO_NetDebugState = createHashMapFromArray [
    ["windowStartedAt", diag_tickTime],
    ["windowSeconds", if ("windowSeconds" in _snapshot) then { _snapshot get "windowSeconds" } else { 60 }],
    ["counters", createHashMap]
];

_snapshot
