/* Resolves one side's configured attack coverage into a per-objective cap. */
params [
    ["_coverageMultiplier", 0, [0]],
    ["_hardCap", 0, [0]]
];

if !(_coverageMultiplier in [0.5, 0.75, 1, 1.25]) then {
    throw format ["Unsupported attack coverage multiplier %1", _coverageMultiplier];
};
if (_hardCap <= 0) then {
    throw format ["Invalid attack coverage hard cap %1", _hardCap];
};

((round (_hardCap * (_coverageMultiplier / 1.25))) max 1) min _hardCap
