/* Returns the date array represented by the monotonic campaign clock. */
private _dateNumber = call FLO_fnc_operationalDateNumber;
numberToDate [FLO_OperationalClock get "year", _dateNumber]
