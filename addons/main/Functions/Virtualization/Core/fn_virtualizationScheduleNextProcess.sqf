/*
 * Function: FLO_fnc_virtualizationScheduleNextProcess
 * Description:
 *   Assigns the next due time for a processed virtual group. Live, attached,
 *   always-active, and player-near groups remain on the full registry sweep.
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_nearestDistance", 999999, [0]],
    ["_activationDistance", 2000, [0]],
    ["_now", 0, [0]]
];

private _interval = 1;
private _fullSweep = (
    (_groupData get "isActive")
    || {_groupData get "alwaysActive"}
    || {(_groupData get "attachedTo") != ""}
    || {_nearestDistance <= (_activationDistance * 1.25)}
);

if (_fullSweep) then {
    _interval = 0;
} else {
    private _urgent = (
        (_groupData get "activationDeferred")
        || {(_groupData get "missionLock") != ""}
        || {_groupData get "inCombat"}
        || {_groupData get "engagementActive"}
        || {(_groupData get "replacementState") != ""}
    );

    if (_urgent) then {
        _interval = 0.25;
    } else {
        if ((_groupData get "waypoints") isNotEqualTo []) then {
            _interval = 0.5;
        };
    };
};

_groupData set ["lastProcessedAt", _now];
_groupData set ["nextProcessAt", _now + _interval];

_interval
