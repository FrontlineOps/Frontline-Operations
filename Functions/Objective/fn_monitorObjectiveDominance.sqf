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
if (isNil "FLO_Objectives") exitWith {};

private _captureTime = 60;      // seconds needed to capture
private _checkInterval = 5;     // time between checks

while {true} do {
    if (isNil "FLO_Objectives") exitWith {};
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

    sleep _checkInterval;
};
