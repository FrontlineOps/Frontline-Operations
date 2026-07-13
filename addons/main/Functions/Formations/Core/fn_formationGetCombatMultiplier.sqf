/* Returns the bounded readiness/veterancy multiplier for one group. */
params [["_groupId", "", [""]]];

if (isNil "FLO_FormationState") then { throw "Formation combat power requested before initialization"; };
if (_groupId == "") then { throw "Formation combat power requested for an empty group ID"; };
private _index = FLO_FormationState get "groupToFormation";
if !(_groupId in _index) exitWith { 1 };
private _formation = (FLO_FormationState get "formations") get (_index get _groupId);
private _readiness = _formation get "readiness";
private _readinessMultiplier = switch true do {
    case (_readiness < 25): { 0.65 };
    case (_readiness < 50): { 0.75 };
    case (_readiness < 75): { 0.90 };
    case (_readiness < 90): { 1.00 };
    default { 1.08 };
};
private _rankMultiplier = switch ([_formation get "experience"] call FLO_fnc_formationGetRank) do {
    case "GREEN": { 0.92 };
    case "REGULAR": { 1.00 };
    case "VETERAN": { 1.08 };
    case "ELITE": { 1.14 };
};

((_readinessMultiplier * _rankMultiplier) max 0.60) min 1.20
