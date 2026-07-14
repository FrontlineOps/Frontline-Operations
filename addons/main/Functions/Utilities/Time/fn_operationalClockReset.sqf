/* Realigns the campaign clock after mission date restoration. */
private _missionDate = date;
private _year = _missionDate select 0;
private _dateNumber = dateToNumber _missionDate;

FLO_OperationalClock set ["year", _year];
FLO_OperationalClock set ["dateNumber", _dateNumber];
FLO_OperationalClock set ["lastMissionYear", _year];
FLO_OperationalClock set ["lastMissionDateNumber", _dateNumber];
FLO_OperationalClock set ["lastTick", diag_tickTime];

["TIME", 3, format ["Operational clock aligned to %1", _missionDate]] call FLO_fnc_log;
true
