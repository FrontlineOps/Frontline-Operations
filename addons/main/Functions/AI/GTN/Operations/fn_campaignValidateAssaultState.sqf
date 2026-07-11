/* Validates one operation's persisted ASSAULT wave ledger. */
params ["_operation"];

private _operationId = _operation get "operationId";
private _packageTarget = _operation get "assaultPackageTarget";
private _activeTarget = _operation get "assaultActiveTarget";
private _waveSize = _operation get "assaultWaveSize";
private _committed = _operation get "assaultCommittedTotal";
private _losses = _operation get "assaultLosses";
private _waveSequence = _operation get "assaultWaveSequence";
private _pauseCount = _operation get "assaultPauseCount";

if (
    _packageTarget < 0
    || {_activeTarget < 0}
    || {_waveSize < 0}
    || {_committed < 0}
    || {_losses < 0}
    || {_waveSequence < 0}
    || {_pauseCount < 0}
) then {
    throw format ["Operation %1 has negative ASSAULT wave state", _operationId];
};
if (_committed > _packageTarget) then {
    throw format ["Operation %1 committed %2 groups from package %3", _operationId, _committed, _packageTarget];
};
if (_losses > _committed) then {
    throw format ["Operation %1 reports %2 losses from %3 commitments", _operationId, _losses, _committed];
};
if (_activeTarget > _packageTarget || {_waveSize > _activeTarget}) then {
    throw format [
        "Operation %1 has invalid package/active/wave policy %2/%3/%4",
        _operationId,
        _packageTarget,
        _activeTarget,
        _waveSize
    ];
};
if ((_operation get "phase") == "ASSAULT" && {_packageTarget <= 0}) then {
    throw format ["Operation %1 is in ASSAULT without initialized wave state", _operationId];
};

true
