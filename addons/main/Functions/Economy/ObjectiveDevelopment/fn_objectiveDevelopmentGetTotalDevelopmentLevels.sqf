params [["_side", sideUnknown, [west]]];

if !(_side in [west, east]) then {
    throw format ["Invalid side for total Development levels: %1", _side];
};

private _total = 0;
{
    if ((_y get "owner") isNotEqualTo _side) then { continue };
    private _level = _y get "developmentLevel";
    if !(_level isEqualType 0 && {_level >= 0} && {_level == floor _level}) then {
        throw format ["Objective %1 has invalid Development level %2", _x, _level];
    };
    _total = _total + _level;
} forEach FLO_Objectives;

_total
