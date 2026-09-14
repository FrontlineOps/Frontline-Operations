/* One identifiable worker for automatic and authenticated manual requests. */
params [["_requesterOwner", -1, [0]]];
if (!isServer || {remoteExecutedOwner > 2}) exitWith { false };
private _accepted = false;
isNil {
    if (FLO_MissionReady && {!FLO_MissionSaveInProgress}
        && {!((FLO_SaveStatus get "phase") in ["QUEUED", "SAVING"])}) then {
        FLO_SaveRequester = _requesterOwner;
        FLO_SaveSequence = FLO_SaveSequence + 1;
        FLO_SaveStatus set ["phase", "QUEUED"];
        FLO_SaveStatus set ["lastAttemptAt", diag_tickTime];
        FLO_SaveWorker = [FLO_SaveSequence] spawn FLO_fnc_MissionSave;
        _accepted = true;
    };
};
if (!_accepted) exitWith { false };
[
    { params ["_worker"]; scriptDone _worker },
    {
        params ["_worker", "_sequence"];
        if (FLO_SaveSequence == _sequence && {FLO_SaveWorker isEqualTo _worker} && {(FLO_SaveStatus get "phase") in ["QUEUED", "SAVING"]}) then {
            // A dead script cannot execute its own cleanup. Never release a living worker.
            [false, "Save worker stopped before reporting a transaction outcome"] call FLO_fnc_saveFinish;
        };
    },
    [FLO_SaveWorker, FLO_SaveSequence]
] call CBA_fnc_waitUntilAndExecute;
true
