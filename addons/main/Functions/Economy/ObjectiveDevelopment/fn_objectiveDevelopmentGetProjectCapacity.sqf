params [["_side", sideUnknown, [west]]];

private _total = [_side] call FLO_fnc_objectiveDevelopmentGetTotalDevelopmentLevels;
private _base = FLO_ObjectiveDevelopmentConfig get "baseProjectSlots";
private _divisor = FLO_ObjectiveDevelopmentConfig get "projectSlotDivisor";
_base + floor (sqrt (_total / _divisor))
