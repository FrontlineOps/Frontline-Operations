/* Refreshes only civilian objective contexts whose authoritative inputs changed. */
params ["_manager"];

private _contexts = _manager get "_objectiveContexts";
private _signatures = _manager get "_objectiveContextSignatures";
private _roles = ["resident", "vendor", "worker", "wanderer", "driver", "watcher"];
private _sides = [east, west];
private _removedObjectives = 0;
private _changedObjectives = 0;
private _rebuiltContexts = 0;

{
    private _objectiveId = _x;
    if (_objectiveId in FLO_Objectives) then { continue };

    {
        private _side = _x;
        {
            _contexts deleteAt format ["%1|%2|%3", _objectiveId, _x, _side];
        } forEach _roles;
    } forEach _sides;
    _signatures deleteAt _objectiveId;
    _removedObjectives = _removedObjectives + 1;
} forEach (keys _signatures);

private _reputation = FLO_ReputationHandle get "value";
{
    private _objectiveId = _x;
    private _objective = _y;
    private _signature = format [
        "%1|%2|%3|%4|%5",
        _objective get "owner",
        _objective get "contested",
        _objective get "bluforCount",
        _objective get "opforCount",
        _reputation
    ];

    if (_objectiveId in _signatures && {(_signatures get _objectiveId) == _signature}) then { continue };

    {
        private _side = _x;
        {
            private _role = _x;
            private _cacheKey = format ["%1|%2|%3", _objectiveId, _role, _side];
            _contexts set [_cacheKey, [_objectiveId, _role, _side] call FLO_fnc_civilianResolveObjectiveContext];
            _rebuiltContexts = _rebuiltContexts + 1;
        } forEach _roles;
    } forEach _sides;

    _signatures set [_objectiveId, _signature];
    _changedObjectives = _changedObjectives + 1;
} forEach FLO_Objectives;

createHashMapFromArray [
    ["totalContexts", count (keys _contexts)],
    ["rebuiltContexts", _rebuiltContexts],
    ["changedObjectives", _changedObjectives],
    ["removedObjectives", _removedObjectives]
]
