/*
 * Function: FLO_fnc_civilianResolveObjectiveContext
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves civilian mood and intel policy for one objective from objective
 *   ownership, contest state, local force balance, and global player reputation.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Civilian role <STRING>
 * 2: Reporting side <SIDE>
 *
 * Return Value:
 * HASHMAP - Objective civilian context
 */

params [
    ["_objectiveId", "", [""]],
    ["_civilianRole", "resident", [""]],
    ["_reportingSide", west, [east]]
];

private _context = createHashMapFromArray [
    ["objectiveId", _objectiveId],
    ["disposition", "HOSTILE"],
    ["owner", sideUnknown],
    ["contested", false],
    ["trustScore", 0],
    ["intelChance", 0],
    ["intelCost", 8],
    ["hostileReportChance", 0.5]
];

if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) exitWith { _context };

private _objective = FLO_Objectives get _objectiveId;
private _cfg = FLO_CivilianConfig;
private _owner = _objective get "owner";
private _contested = _objective get "contested";
private _reputation = FLO_ReputationHandle get "value";

private _friendlyTier = switch (true) do {
    case (_reputation >= (_cfg get "REP_FRIENDLY")): { 3 };
    case (_reputation >= (_cfg get "REP_NEUTRAL")): { 2 };
    case (_reputation >= (_cfg get "REP_WARY")): { 1 };
    default { 0 };
};

private _friendlyCountKey = if (_reportingSide isEqualTo west) then { "bluforCount" } else { "opforCount" };
private _enemyCountKey = if (_reportingSide isEqualTo west) then { "opforCount" } else { "bluforCount" };
private _friendlyCount = _objective get _friendlyCountKey;
private _enemyCount = _objective get _enemyCountKey;

if (_owner in [east, west] && {_owner != _reportingSide}) then {
    _friendlyTier = (_friendlyTier - 2) max 0;
};
if (_contested) then {
    _friendlyTier = (_friendlyTier - 1) max 0;
};
if (_enemyCount > _friendlyCount) then {
    _friendlyTier = (_friendlyTier - 1) max 0;
};

private _roleTrustBonus = switch (_civilianRole) do {
    case "vendor": { 0.08 };
    case "resident": { 0.05 };
    case "watcher": { -0.05 };
    default { 0 };
};
private _roleKnowledgeBonus = switch (_civilianRole) do {
    case "watcher": { 0.1 };
    case "driver": { 0.08 };
    case "worker": { 0.05 };
    default { 0 };
};

private _disposition = ["HOSTILE", "WARY", "NEUTRAL", "FRIENDLY"] select _friendlyTier;
private _trustScore = ([0.08, 0.28, 0.56, 0.82] select _friendlyTier) + _roleTrustBonus;
private _intelChance = ([0.05, 0.25, 0.5, 0.78] select _friendlyTier) + _roleKnowledgeBonus;
private _hostileReportChance = [0.45, 0.22, 0.08, 0.0] select _friendlyTier;
private _intelCost = [8, 6, 5, 3] select _friendlyTier;

_context set ["disposition", _disposition];
_context set ["owner", _owner];
_context set ["contested", _contested];
_context set ["trustScore", (_trustScore max 0) min 0.95];
_context set ["intelChance", (_intelChance max 0) min 0.95];
_context set ["intelCost", _intelCost];
_context set ["hostileReportChance", _hostileReportChance];

_context
