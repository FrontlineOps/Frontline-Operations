/*
 * Function: FLO_fnc_civilianSelectObjectiveMemory
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the best civilian memory candidate for a given objective and
 *   civilian role, preferring local memories over weaker linked-objective
 *   rumors.
 *
 * Arguments:
 * 0: Objective memory ledger <HASHMAP>
 * 1: Objective ID <STRING>
 * 2: Civilian role <STRING>
 * 3: Current time tick <NUMBER>
 *
 * Return Value:
 * HASHMAP - Selected memory or empty hashmap
 */

params [
    ["_ledger", createHashMap, [createHashMap]],
    ["_objectiveId", "", [""]],
    ["_civilianRole", "resident", [""]],
    ["_nowTick", diag_tickTime, [0]]
];

private _selected = createHashMap;
if (_objectiveId == "" || {!(isNil "FLO_Objectives") && {!(_objectiveId in FLO_Objectives)}}) exitWith { _selected };

private _candidateObjectives = [_objectiveId];
if (!isNil "FLO_Objectives" && {_objectiveId in FLO_Objectives}) then {
    {
        _candidateObjectives pushBackUnique _x;
    } forEach ((FLO_Objectives get _objectiveId) get "linkedObjectives");
};

private _bestScore = -1;
private _retention = FLO_CivilianConfig get "MEMORY_RETENTION_SECONDS";

{
    if !(_x in _ledger) then { continue };

    {
        private _memory = _x;
        if ((_memory get "expiresAt") <= _nowTick) then { continue };

        private _score = _memory get "confidence";
        _score = _score + (((_memory get "expiresAt") - _nowTick) / _retention);

        if ((_memory get "objectiveId") == _objectiveId) then {
            _score = _score + 0.35;
        } else {
            _score = _score - 0.12;
        };

        _score = _score - ((_memory get "gossipDepth") * 0.12);

        private _reportType = _memory get "reportType";
        switch (_civilianRole) do {
            case "watcher": {
                if (_reportType in ["PATROL_SIGHTING", "CHECKPOINT_RUMOR", "HOSTILE_REPORT"]) then {
                    _score = _score + 0.15;
                };
            };
            case "driver": {
                if (_reportType in ["VEHICLE_MOVEMENT", "CHECKPOINT_RUMOR", "SAFE_ROUTE_HINT"]) then {
                    _score = _score + 0.15;
                };
            };
            case "vendor": {
                if (_reportType in ["CHECKPOINT_RUMOR", "SAFE_ROUTE_HINT"]) then {
                    _score = _score + 0.1;
                };
            };
            default {
                if (_reportType == "HOSTILE_REPORT") then {
                    _score = _score + 0.05;
                };
            };
        };

        if (_score > _bestScore) then {
            _bestScore = _score;
            _selected = _memory;
        };
    } forEach (_ledger get _x);
} forEach _candidateObjectives;

_selected
