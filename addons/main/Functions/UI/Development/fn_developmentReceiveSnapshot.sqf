params ["_snapshot"];

if (!hasInterface) exitWith {};

FLO_DevelopmentLastSnapshot = _snapshot;
[_snapshot] call FLO_fnc_developmentUpdateDialog;
