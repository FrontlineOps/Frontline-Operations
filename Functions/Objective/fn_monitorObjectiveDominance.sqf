/*
 * Function: FLO_fnc_monitorObjectiveDominance
 * Author: Frontline Operations Development Group
 * Description:
 *   Continuously checks player presence at objectives and flips ownership
 *   when one side holds dominance for a period of time.
 *
 * Arguments: None
 *
 * Example:
 *   [] spawn FLO_fnc_monitorObjectiveDominance;
 */

if (!isServer) exitWith {};
["OBJECTIVEMONITOR", 3, "MonitorObjectiveDominance function started"] call FLO_fnc_log;

// Wait for objectives to be initialized
if (isNil "FLO_Objectives") then {
    ["OBJECTIVEMONITOR", 3, "Waiting for FLO_Objectives to be initialized..."] call FLO_fnc_log;
    waitUntil {!isNil "FLO_Objectives"};
    ["OBJECTIVEMONITOR", 3, "FLO_Objectives initialized, starting monitoring"] call FLO_fnc_log;
};

private _captureTime = 20;      // seconds needed to capture
private _checkInterval = 5;     // time between checks

while {true} do {
    // Safety check in case FLO_Objectives gets undefined during runtime
    if (isNil "FLO_Objectives") then {
        ["OBJECTIVEMONITOR", 2, "FLO_Objectives became undefined, waiting for reinitialization..."] call FLO_fnc_log;
        waitUntil {!isNil "FLO_Objectives"};
        ["OBJECTIVEMONITOR", 3, "FLO_Objectives reinitialized, resuming monitoring"] call FLO_fnc_log;
    };
    ["OBJECTIVEMONITOR", 3, "Starting objective check loop"] call FLO_fnc_log;
    {
        private _id = _x;
        private _data = FLO_Objectives get _id;
        if (isNil "_data") then { continue }; 

        private _pos = _data get "position";
        private _radius = _data get "radius";
        private _owner = _data getOrDefault ["owner", east];
        private _progress = _data getOrDefault ["captureProgress", 0];

        private _bluforCount = { alive _x && side _x isEqualTo west && (_x distance2D _pos < _radius) } count allUnits;
        private _opforCount  = { alive _x && side _x isEqualTo east && (_x distance2D _pos < _radius) } count allUnits;

        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups get "_groups";
            {
                private _gId = _x;
                private _gData = _y;
                if (!isNil "_gData") then {
                    if ((_gData getOrDefault ["side", east]) isEqualTo east && {!(_gData getOrDefault ["isActive", false])}) then {
                        private _gPos = _gData getOrDefault ["position", [0,0,0]];
                        if (_gPos distance2D _pos < _radius) then {
                            _opforCount = _opforCount + (_gData getOrDefault ["unitCount", 0]);
                        };
                    };
                };
            } forEach _groups;
        };

        if (_bluforCount > _opforCount && _bluforCount > 0) then {
            _progress = (_progress + _checkInterval) min _captureTime;
        } else {
            if (_opforCount > _bluforCount && _opforCount > 0) then {
                _progress = (_progress - _checkInterval) max (-_captureTime);
            } else {
                if (_progress > 0) then { _progress = (_progress - _checkInterval) max 0 };
                if (_progress < 0) then { _progress = (_progress + _checkInterval) min 0 };
            };
        };

        if (_progress >= _captureTime && {_owner != west}) then {
            [_id, west] call FLO_fnc_flipObjective;
            _owner = west;
            _progress = 0;
            [0.20, "increase"] call FLO_fnc_adjustAggression;
        } else {
            if (_progress <= -_captureTime && {_owner != east}) then {
                [_id, east] call FLO_fnc_flipObjective;
                _owner = east;
                _progress = 0;
                [-0.10, "decrease"] call FLO_fnc_adjustAggression;
            };
        };

        _data set ["captureProgress", _progress];
        FLO_Objectives set [_id, _data];
    } forEach (keys FLO_Objectives);

    ["OBJECTIVEMONITOR", 3, "Objective checking is complete"] call FLO_fnc_log;

    sleep _checkInterval;
};
