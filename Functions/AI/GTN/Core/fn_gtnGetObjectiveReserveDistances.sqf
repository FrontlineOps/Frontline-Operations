/*
 * Function: FLO_fnc_gtnGetObjectiveReserveDistances
 * Author: Frontline Operations Development Group
 *
 * Description:
 * Derive local reserve and max pull distances for one objective from nearby
 * objective graph spacing. Dense sectors stay tight; sparse sectors scale wider.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Objective ID <STRING>
 * 2: Mode <STRING> ("attack" or "defense")
 *
 * Return Value:
 * [localReserveMeters, maxPullDistanceMeters] <ARRAY>
 */

params [
    ["_cmdr", nil],
    ["_objectiveId", "", [""]],
    ["_mode", "attack", [""]]
];

private _config = _cmdr get "_config";
private _ws = _cmdr get "_worldState";
private _objectives = _ws call ["_getObjectives", []];
private _objective = _objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _ownSide = _cmdr get "_ownSide";

private _localReserveMeters = 0;
private _maxPullDistanceMeters = 0;
private _localMultiplier = 0;
private _maxMultiplier = 0;
private _pullCapMeters = 0;

if (_mode == "attack") then {
    _localReserveMeters = _config get "attackLocalReserveMeters";
    _maxPullDistanceMeters = _config get "attackMaxPullDistanceMeters";
    _localMultiplier = _config get "attackLocalReserveSpacingMultiplier";
    _maxMultiplier = _config get "attackMaxPullSpacingMultiplier";
    _pullCapMeters = _config get "attackDynamicPullCapMeters";
} else {
    _localReserveMeters = _config get "defenseLocalReserveMeters";
    _maxPullDistanceMeters = _config get "defenseMaxPullDistanceMeters";
    _localMultiplier = _config get "defenseLocalReserveSpacingMultiplier";
    _maxMultiplier = _config get "defenseMaxPullSpacingMultiplier";
    _pullCapMeters = _config get "defenseDynamicPullCapMeters";
};

private _distanceSamples = [];

if (_mode == "attack") then {
    private _sourceObjectives = _cmdr call ["_getFriendlyAttackSourceObjectives", [_objectiveId]];

    {
        private _sourceObjective = _objectives get _x;
        private _sourcePos = _sourceObjective get "position";
        _distanceSamples pushBack (_objectivePos distance2D _sourcePos);

        {
            private _linkedObjective = _objectives get _x;
            if ((_linkedObjective get "owner") != _ownSide) then { continue };
            _distanceSamples pushBack (_sourcePos distance2D (_linkedObjective get "position"));
        } forEach (_sourceObjective get "linkedObjectives");
    } forEach _sourceObjectives;
} else {
    private _friendlyLinkCount = 0;

    {
        private _linkedObjective = _objectives get _x;
        if ((_linkedObjective get "owner") != _ownSide) then { continue };

        _friendlyLinkCount = _friendlyLinkCount + 1;
        _distanceSamples pushBack (_objectivePos distance2D (_linkedObjective get "position"));
    } forEach (_objective get "linkedObjectives");

    if (_friendlyLinkCount == 0) then {
        {
            private _linkedObjective = _objectives get _x;
            _distanceSamples pushBack (_objectivePos distance2D (_linkedObjective get "position"));
        } forEach (_objective get "linkedObjectives");
    };
};

if ((count _distanceSamples) > 0) then {
    private _distanceSum = 0;
    {
        _distanceSum = _distanceSum + _x;
    } forEach _distanceSamples;

    private _graphSpacingMeters = _distanceSum / (count _distanceSamples);
    _localReserveMeters = _localReserveMeters max (ceil (_graphSpacingMeters * _localMultiplier));
    _maxPullDistanceMeters = _maxPullDistanceMeters max (ceil (_graphSpacingMeters * _maxMultiplier));
};

_maxPullDistanceMeters = _maxPullDistanceMeters min _pullCapMeters;
_localReserveMeters = (_localReserveMeters min _maxPullDistanceMeters) max 0;

[_localReserveMeters, _maxPullDistanceMeters]
