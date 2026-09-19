/* Releases one live unit from FLO-owned physical building-garrison state. */
params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith { true };
if !(local _unit) then {
    ["VIRTUALIZATION", 1, format ["Cannot release non-local garrison unit %1", _unit]] call FLO_fnc_log;
    throw format ["FLO_fnc_taskReleaseGarrisonUnit: unit %1 is not local", _unit];
};

{
    _x params ["_eventType", "_eventId"];
    _unit removeEventHandler [_eventType, _eventId];
} forEach (_unit getVariable ["FLO_garrisonEventHandlers", []]);

_unit setVariable ["FLO_garrisonEventHandlers", nil];
_unit setVariable ["FLO_garrisonPosition", nil];
_unit enableAI "PATH";
_unit setUnitPos "AUTO";

true
