private _emitSorted = {
    params ["_map"];

    private _pairs = [];
    {
        _pairs pushBack [(_map get _x), _x];
    } forEach (keys _map);
    _pairs sort false;
    _pairs apply { [_x select 1, _x select 0] }
};

[
    ["attempts", [(FLO_PF_SourceStats get "attempts")] call _emitSorted],
    ["newSearch", [(FLO_PF_SourceStats get "newSearch")] call _emitSorted],
    ["cacheHit", [(FLO_PF_SourceStats get "cacheHit")] call _emitSorted],
    ["pendingJoin", [(FLO_PF_SourceStats get "pendingJoin")] call _emitSorted]
]
