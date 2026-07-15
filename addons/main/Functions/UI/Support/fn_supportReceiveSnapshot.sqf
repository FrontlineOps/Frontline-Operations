params ["_snapshot"];

if (!hasInterface) exitWith { false };

FLO_SupportLastServerSnapshot = _snapshot;
[] call FLO_fnc_supportUpdateDialog;
["UI", 4, format [
    "Tactical Support snapshot received side=%1 assets=%2",
    _snapshot get "sideKey",
    count (_snapshot get "assets")
]] call FLO_fnc_log;
true
