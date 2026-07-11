/*
 * Function: FLO_fnc_gtnRequestFrontlineCAP
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Requests one opportunistic CAP mission for the best threatened friendly
 *   frontline objective with recent enemy air contacts. Uses maintained GTN
 *   world-state intel and per-objective locks to avoid CAP spam.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAP>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["assetAvailable", false],
    ["airContactCount", 0],
    ["candidateCount", 0],
    ["eligibleCount", 0],
    ["lockedCount", 0],
    ["requestedCount", 0],
    ["selectedObjective", ""],
    ["selectedScore", 0]
];

if (isNil "_cmdr") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
if !(_ws call ["_isAssetAvailable", ["cap"]]) exitWith { _metrics };
_metrics set ["assetAvailable", true];

private _objectives = _ws call ["_getObjectives", []];
if ((keys _objectives) isEqualTo []) exitWith { _metrics };

private _enemyIntel = _ws call ["_getEnemyIntel", []];
private _contactReports = _enemyIntel get "contactReports";
if (_contactReports isEqualTo []) exitWith { _metrics };

private _cfg = _cmdr get "_config";
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _contactFreshSeconds = _cfg get "frontlineCAPContactFreshSeconds";
private _contactRadiusMeters = _cfg get "frontlineCAPContactRadiusMeters";
private _minThreatScore = _cfg get "frontlineCAPMinThreatScore";
private _lockSeconds = _cfg get "frontlineCAPObjectiveLockSeconds";
private _locks = _cmdr get "_frontlineCAPLocks";
private _now = diag_tickTime;

private _expiredLocks = [];
{
    private _objectiveId = _x;
    private _lockedUntil = _locks get _objectiveId;
    if (_lockedUntil <= _now || !(_objectiveId in _objectives) || {((_objectives get _objectiveId) get "owner") != _ownSide}) then {
        _expiredLocks pushBack _objectiveId;
    };
} forEach (keys _locks);
{ _locks deleteAt _x; } forEach _expiredLocks;

private _recentAirContacts = [];
{
    _x params ["_contactPos", "_contactTime", "_contactStrength", "_contactType", "_contactConfidence"];
    if ((_now - _contactTime) > _contactFreshSeconds) then { continue };
    if (!(_contactType isEqualType "")) then { continue };
    private _cfgVehicle = configFile >> "CfgVehicles" >> _contactType;
    if (!isClass _cfgVehicle) then { continue };
    if !(_contactType isKindOf ["Air", configFile >> "CfgVehicles"]) then { continue };
    _recentAirContacts pushBack _x;
} forEach _contactReports;

_metrics set ["airContactCount", count _recentAirContacts];
if (_recentAirContacts isEqualTo []) exitWith { _metrics };

private _bestObjectiveId = "";
private _bestObjectivePos = [];
private _bestScore = -1e12;

{
    private _objectiveId = _x;
    private _objective = _objectives get _objectiveId;
    if ((_objective get "owner") != _ownSide) then { continue };

    private _linkedObjectives = _objective get "linkedObjectives";
    private _isFrontlineFriendly = ({((_objectives get _x) get "owner") isEqualTo _enemySide} count _linkedObjectives) > 0;
    if !(_isFrontlineFriendly || (_objective get "underAttack") || (_objective get "contested")) then { continue };

    _metrics set ["candidateCount", (_metrics get "candidateCount") + 1];

    if (_objectiveId in _locks) then {
        _metrics set ["lockedCount", (_metrics get "lockedCount") + 1];
        continue;
    };

    private _objectivePos = _objective get "position";
    private _objectiveAirScore = 0;
    private _objectiveAirContacts = 0;

    {
        _x params ["_contactPos", "_contactTime", "_contactStrength", "_contactType", "_contactConfidence"];
        private _distance = _objectivePos distance2D _contactPos;
        if (_distance > _contactRadiusMeters) then { continue };

        _objectiveAirContacts = _objectiveAirContacts + 1;

        private _ageSeconds = _now - _contactTime;
        private _ageWeight = linearConversion [0, _contactFreshSeconds, _ageSeconds, 1, 0.2, true];
        private _distanceWeight = linearConversion [0, _contactRadiusMeters, _distance, 1, 0.25, true];
        private _contactScore = (((_contactStrength max 1) * 12) + ((_contactConfidence max 0) * 25)) * _ageWeight * _distanceWeight;
        _objectiveAirScore = _objectiveAirScore + _contactScore;
    } forEach _recentAirContacts;

    if (_objectiveAirContacts == 0) then { continue };

    _metrics set ["eligibleCount", (_metrics get "eligibleCount") + 1];

    private _score = _objectiveAirScore + ((_objective get "priority") * 0.4) + ((_objective get "enemyCount") * 6);
    if (_objective get "underAttack") then {
        _score = _score + 25;
    };
    if (_objective get "contested") then {
        _score = _score + 20;
    };
    if (_isFrontlineFriendly) then {
        _score = _score + 10;
    };

    if (_score > _bestScore) then {
        _bestObjectiveId = _objectiveId;
        _bestObjectivePos = _objectivePos;
        _bestScore = _score;
    };
} forEach (keys _objectives);

if (_bestObjectiveId == "" || {_bestScore < _minThreatScore}) exitWith { _metrics };

private _success = _cmdr call ["_requestCAP", [_bestObjectivePos]];
if (_success) then {
    _locks set [_bestObjectiveId, _now + _lockSeconds];
    _metrics set ["requestedCount", 1];
    _metrics set ["selectedObjective", _bestObjectiveId];
    _metrics set ["selectedScore", _bestScore];

    ["GTN", 3, format [
        "Frontline CAP requested for %1 (score=%2)",
        _bestObjectiveId,
        round _bestScore
    ]] call FLO_fnc_log;
};

_metrics
