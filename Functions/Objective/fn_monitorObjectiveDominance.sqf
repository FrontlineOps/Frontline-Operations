/*
 * Function: FLO_fnc_monitorObjectiveDominance
 * Author: Frontline Operations Development Group
 * Description:
 *   Continuously checks unit presence at objectives and flips ownership
 *   when one side holds dominance for a period of time.
 *   Uses isPositionInObjective for accurate containment checks.
 *
 * Arguments: None
 *
 * Returns: Nothing (runs indefinitely)
 *
 * Example:
 *   [] spawn FLO_fnc_monitorObjectiveDominance;
 */

if (!isServer) exitWith {};

["OBJECTIVEMONITOR", 2, "MonitorObjectiveDominance started"] call FLO_fnc_log;

// Wait for objectives to be initialized
waitUntil { !isNil "FLO_Objectives" };
["OBJECTIVEMONITOR", 3, "FLO_Objectives initialized"] call FLO_fnc_log;

// Get config values
private _captureTime = ["get", "captureTime"] call FLO_fnc_objectiveConfig;
private _checkInterval = ["get", "checkInterval"] call FLO_fnc_objectiveConfig;

while {true} do {
    // Safety check
    if (isNil "FLO_Objectives") then {
        ["OBJECTIVEMONITOR", 2, "FLO_Objectives undefined, waiting..."] call FLO_fnc_log;
        waitUntil { !isNil "FLO_Objectives" };
    };

    {
        private _id = _x;
        private _data = FLO_Objectives get _id;
        if (isNil "_data") then { continue };

        private _pos = _data get "position";
        private _owner = _data getOrDefault ["owner", east];
        private _progress = _data getOrDefault ["captureProgress", 0];

        // Count units in objective using centralized check
        private _bluforCount = 0;
        private _opforCount = 0;

        {
            if (alive _x) then {
                private _unitPos = getPos _x;
                if ([_unitPos, _data] call FLO_fnc_isPositionInObjective) then {
                    switch (side _x) do {
                        case west: { _bluforCount = _bluforCount + 1 };
                        case east: { _opforCount = _opforCount + 1 };
                    };
                };
            };
        } forEach allUnits;

        // Include virtual groups
        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups getOrDefault ["_groups", createHashMap];
            {
                private _gData = _y;
                if (isNil "_gData") then { continue };

                private _gSide = _gData getOrDefault ["side", east];
                private _isActive = _gData getOrDefault ["isActive", false];

                if (_gSide isEqualTo east && {!_isActive}) then {
                    private _gPos = _gData getOrDefault ["position", [0,0,0]];
                    if ([_gPos, _data] call FLO_fnc_isPositionInObjective) then {
                        _opforCount = _opforCount + (_gData getOrDefault ["unitCount", 0]);
                    };
                };
            } forEach _groups;
        };

        // Update capture progress
        if (_bluforCount > _opforCount && {_bluforCount > 0}) then {
            _progress = (_progress + _checkInterval) min _captureTime;
        } else {
            if (_opforCount > _bluforCount && {_opforCount > 0}) then {
                _progress = (_progress - _checkInterval) max (-_captureTime);
            } else {
                // Decay towards neutral
                if (_progress > 0) then { _progress = (_progress - _checkInterval) max 0 };
                if (_progress < 0) then { _progress = (_progress + _checkInterval) min 0 };
            };
        };

        // Check for capture
        if (_progress >= _captureTime && {_owner != west}) then {
            [_id, west] call FLO_fnc_flipObjective;
            _progress = 0;
            [0.20, "increase"] call FLO_fnc_adjustAggression;
        } else {
            if (_progress <= -_captureTime && {_owner != east}) then {
                [_id, east] call FLO_fnc_flipObjective;
                _progress = 0;
                [-0.10, "decrease"] call FLO_fnc_adjustAggression;
            };
        };

        // Store progress
        _data set ["captureProgress", _progress];
        FLO_Objectives set [_id, _data];
    } forEach (keys FLO_Objectives);

    sleep _checkInterval;
};
