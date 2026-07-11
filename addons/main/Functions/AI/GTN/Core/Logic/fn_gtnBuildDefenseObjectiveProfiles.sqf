/* Precomputes the stable defense-priority band for each friendly objective. */
params [
    "_objectives",
    ["_ownSide", sideUnknown, [west]],
    ["_enemySide", sideUnknown, [east]]
];

private _profiles = createHashMap;
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") isNotEqualTo _ownSide) then { continue };

    private _priorityBand = 3;
    if ((_objective get "underAttack") || {_objective get "contested"}) then {
        _priorityBand = 0;
    } else {
        private _frontlineThreat = (_objective get "enemyCount") > 0;
        if (!_frontlineThreat) then {
            {
                if (((_objectives get _x) get "owner") isEqualTo _enemySide) exitWith {
                    _frontlineThreat = true;
                };
            } forEach (_objective get "linkedObjectives");
        };
        if (_frontlineThreat) then { _priorityBand = 1; };
    };

    _profiles set [_objectiveId, _priorityBand];
} forEach _objectives;

_profiles
