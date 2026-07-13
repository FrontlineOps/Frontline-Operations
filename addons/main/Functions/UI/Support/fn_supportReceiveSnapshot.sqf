params ["_snapshot"];

if (!hasInterface) exitWith { false };

FLO_SupportLastServerSnapshot = _snapshot;
[] call FLO_fnc_supportUpdateDialog;
diag_log format [
    "[FLO][Support] Snapshot received side=%1 assets=%2",
    _snapshot get "sideKey",
    count (_snapshot get "assets")
];
true
