params [["_level", -1, [0]]];

if (_level < 0 || {_level > 3} || {floor _level != _level}) then {
    throw format ["Invalid objective development level %1", _level];
};

private _tiers = FLO_ObjectiveDevelopmentConfig get "tiers";
_tiers get str _level
