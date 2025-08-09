/*
 * Function: FLO_fnc_backgroundEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Lightweight background world events to keep players engaged between main missions:
 *   - Periodically triggers a side mission or reveals nearby enemy activity
 *   - Uses notifications to inform players of activity
 */

if (!isServer) exitWith {};

[] spawn {
    if (!isServer) exitWith {};

    // Timings (local to spawned scope)
    private _minInterval = 180; // 3 minutes
    private _maxInterval = 300; // 5 minutes

    sleep (30 + random 15); // staggered start

    while {true} do {
        private _roll = random 1;

        if (_roll < 0.5) then {
            // Start a random side mission via intel system
            [] call FLO_fnc_militaryIntel;
            ["STR_FLO_INTEL_TITLE", ["Background mission opportunity"], "intel"] call FLO_fnc_sendNotification;
        } else {
            // Reveal a nearby enemy group for any player - ONLY if intel allows
            private _players = allPlayers select {alive _x};
            private _center = if (count _players > 0) then { selectRandom _players } else { objNull };
            private _intelOK = false;
            if (!isNil "FLO_Intel_System") then {
                private _intelLevel = FLO_Intel_System get "intelLevel";
                // Update/retrieve tower count
                private _radioTowers = if (!isNil "FLO_Intel_System") then { FLO_Intel_System call ["updateRadioTowers", []] } else { 0 };
                _intelOK = (_intelLevel >= 25) && (_radioTowers >= 3);
            };

            if (!isNull _center && _intelOK) then {
                [_center] call FLO_fnc_revealRandomEnemyGroup;
                ["STR_FLO_INTEL_TITLE", ["Enemy activity detected nearby"], "intel"] call FLO_fnc_sendNotification;
            };
        };

        sleep (_minInterval + random (_maxInterval - _minInterval));
    };
};

