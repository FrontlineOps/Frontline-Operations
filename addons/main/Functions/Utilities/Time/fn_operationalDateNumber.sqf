/*
 * Advances strategic time by mission-time or server wall-time, whichever
 * moved farther since the previous observation. This keeps campaigns alive
 * while Arma freezes `date` on an empty dedicated server.
 */
private _clock = FLO_OperationalClock;
private _nowTick = diag_tickTime;
private _missionDate = date;
private _missionYear = _missionDate select 0;
private _missionDateNumber = dateToNumber _missionDate;
private _lastMissionYear = _clock get "lastMissionYear";
private _lastMissionDateNumber = _clock get "lastMissionDateNumber";
private _wallElapsed = (_nowTick - (_clock get "lastTick")) max 0;
private _missionElapsed = 0;

if (_missionYear == _lastMissionYear) then {
    _missionElapsed = [
        _lastMissionDateNumber,
        _missionDateNumber,
        _missionYear
    ] call FLO_fnc_dateNumberDeltaSeconds;
} else {
    if (_missionYear == (_lastMissionYear + 1)) then {
        _missionElapsed = ((1 - _lastMissionDateNumber) * ([_lastMissionYear] call FLO_fnc_dateNumberSecondsPerYear))
            + (_missionDateNumber * ([_missionYear] call FLO_fnc_dateNumberSecondsPerYear));
    };
};
_missionElapsed = _missionElapsed max 0;

private _elapsed = _wallElapsed max _missionElapsed;
private _year = _clock get "year";
private _dateNumber = _clock get "dateNumber";
private _remaining = _elapsed;

while {_remaining > 0} do {
    private _secondsPerYear = [_year] call FLO_fnc_dateNumberSecondsPerYear;
    private _secondsToYearEnd = (1 - _dateNumber) * _secondsPerYear;
    if (_remaining < _secondsToYearEnd) exitWith {
        _dateNumber = _dateNumber + (_remaining / _secondsPerYear);
        _remaining = 0;
    };

    _remaining = _remaining - _secondsToYearEnd;
    _year = _year + 1;
    _dateNumber = 0;
};

_clock set ["year", _year];
_clock set ["dateNumber", _dateNumber];
_clock set ["lastMissionYear", _missionYear];
_clock set ["lastMissionDateNumber", _missionDateNumber];
_clock set ["lastTick", _nowTick];

_dateNumber
