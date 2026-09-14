/* Detached public session status contains no requester identity or saved payload. */
private _lastSuccess = FLO_SaveStatus get "lastSuccessAt";
private _lastAttempt = FLO_SaveStatus get "lastAttemptAt";
createHashMapFromArray [
    ["phase", FLO_SaveStatus get "phase"],
    ["lastSuccessAge", if (_lastSuccess < 0) then { -1 } else { diag_tickTime - _lastSuccess }],
    ["attemptAge", if (_lastAttempt < 0) then { -1 } else { diag_tickTime - _lastAttempt }],
    ["duration", FLO_SaveStatus get "duration"],
    ["failures", FLO_SaveStatus get "failures"],
    ["intervalMinutes", FLO_AutosaveIntervalMinutes]
]
