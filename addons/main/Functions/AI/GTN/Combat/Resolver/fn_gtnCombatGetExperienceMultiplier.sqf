/* Returns the bounded virtual-combat multiplier for persistent group experience. */
params [["_experience", 0, [0]]];

switch ([_experience] call FLO_fnc_gtnCombatGetExperienceRank) do {
    case "GREEN": { 0.92 };
    case "REGULAR": { 1.00 };
    case "VETERAN": { 1.08 };
    case "ELITE": { 1.14 };
    default {
        private _message = format ["Unsupported group experience rank for %1", _experience];
        ["GTN_COMBAT", 1, _message] call FLO_fnc_log;
        throw _message;
    };
}
