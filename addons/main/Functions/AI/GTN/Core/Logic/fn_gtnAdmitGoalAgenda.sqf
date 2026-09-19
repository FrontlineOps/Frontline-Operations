params ["_commander"];
private _agenda = _commander get "_goalAgenda";
private _config = _commander get "_config";
private _admitted = 0;
private _attempts = 0;
private _supportAdmitted = createHashMap;
{
    if (_admitted >= (_config get "goalsAdmittedPerCycle") || {count (_commander get "_tracks") >= (_config get "maxActiveGoals")}) exitWith {};
    private _result = [_commander, FLO_fnc_gtnAdmitGoal, [_commander, _x, _supportAdmitted]] call FLO_fnc_gtnRunCycleStep;
    _admitted = _admitted + (_result select 0);
    _attempts = _attempts + (_result select 1);
} forEach _agenda;
createHashMapFromArray [["candidates", count _agenda], ["attempts", _attempts], ["admitted", _admitted]]
