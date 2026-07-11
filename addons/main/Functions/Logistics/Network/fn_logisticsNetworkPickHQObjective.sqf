params ["_network"];

private _managedObjectiveIds = _network get "_managedObjectiveIds";
if (_managedObjectiveIds isEqualTo []) exitWith { "" };

private _persistedObjectiveId = _network get "_hqObjectiveId";
if (_persistedObjectiveId != "" && {_persistedObjectiveId in _managedObjectiveIds}) exitWith { _persistedObjectiveId };

private _startPosition = FLO_MissionConfig get "startPosition";
private _managedSide = _network get "_managedSide";
private _bestObjectiveId = "";
private _bestDistance = [1e12, -1] select (_managedSide isEqualTo east);

{
    private _distance = _startPosition distance2D ((FLO_Objectives get _x) get "position");
    private _isBetter = [_distance < _bestDistance, _distance > _bestDistance] select (_managedSide isEqualTo east);
    if (_isBetter) then {
        _bestDistance = _distance;
        _bestObjectiveId = _x;
    };
} forEach _managedObjectiveIds;

_bestObjectiveId
