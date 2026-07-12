params [["_level", 0, [0]]];

if !(_level >= 0 && {_level == floor _level}) then {
    throw format ["Development level must be a non-negative integer, got %1", _level];
};

(0.5 * _level) / (_level + 5)
