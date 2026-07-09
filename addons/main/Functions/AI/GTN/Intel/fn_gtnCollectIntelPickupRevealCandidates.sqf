/*
 * Function: FLO_fnc_gtnCollectIntelPickupRevealCandidates
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects actionable enemy strategic intel reveal candidates for one
 *   player side from maintained GTN commander and logistics state.
 *
 * Arguments:
 *   0: Player side <SIDE>
 *
 * Return Value:
 *   ARRAY - Reveal candidate hash maps
 */

params [["_playerSide", sideUnknown, [sideUnknown]]];

private _candidates = [];
if !(_playerSide in [east, west]) exitWith { _candidates };

private _enemySide = [east, west] select (_playerSide isEqualTo east);
private _enemySideCtx = [_enemySide] call FLO_fnc_gtnSideContext;
private _enemySideKey = _enemySideCtx get "sideKey";
private _enemyColor = ["ColorBLUFOR", "ColorOPFOR"] select (_enemySide isEqualTo east);

private _enemyCommander = FLO_GTN_CommandersBySide get _enemySideKey;
private _tracks = _enemyCommander get "_tracks";
private _seenTargetObjectives = createHashMap;

{
    if ((_x get "goal") != "capture_priority_objective") then { continue };

    private _objectiveId = _x get "phaseObjectiveId";
    if (_objectiveId == "" || {_objectiveId in _seenTargetObjectives}) then { continue };
    if !(_objectiveId in FLO_Objectives) then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") != _playerSide) then { continue };

    _seenTargetObjectives set [_objectiveId, true];

    private _phase = _x get "phase";
    private _phasePriority = switch (_phase) do {
        case "assault": { 300 };
        case "staging": { 200 };
        case "spent": { 100 };
        default { 50 };
    };

    _candidates pushBack (createHashMapFromArray [
        ["category", "commander_target"],
        ["revealKey", format ["COMMANDER_TARGET|%1", _objectiveId]],
        ["alertType", "INTEL_COMMANDER_TARGET"],
        ["objectiveId", _objectiveId],
        ["objectiveName", _objective get "name"],
        ["position", _objective get "position"],
        ["radius", ((_objective get "radius") max 150) min 450],
        ["duration", 300],
        ["priority", 3000 + _phasePriority + (_objective get "priority")],
        ["message", format ["Recovered enemy comms: commander target identified at %1.", _objective get "name"]],
        ["payload", [
            _objective get "name",
            _phase,
            _enemyColor
        ]]
    ]);
} forEach _tracks;

private _enemyNetwork = FLO_Logistics_Networks get _enemySideKey;
private _activeNodes = _enemyNetwork call ["_refreshSupplyChain", []];
private _hqObjectiveId = _enemyNetwork get "_hqObjectiveId";

if (_hqObjectiveId != "" && {_hqObjectiveId in FLO_Objectives}) then {
    private _hqObjective = FLO_Objectives get _hqObjectiveId;
    _candidates pushBack (createHashMapFromArray [
        ["category", "hq"],
        ["revealKey", format ["HQ|%1", _hqObjectiveId]],
        ["alertType", "INTEL_HQ"],
        ["objectiveId", _hqObjectiveId],
        ["objectiveName", _hqObjective get "name"],
        ["position", _hqObjective get "position"],
        ["radius", ((_hqObjective get "radius") max 180) min 500],
        ["duration", 420],
        ["priority", 2200 + (_hqObjective get "priority")],
        ["message", format ["Recovered enemy command data: HQ identified at %1.", _hqObjective get "name"]],
        ["payload", [
            _hqObjective get "name",
            _enemyColor
        ]]
    ]);
};

{
    private _objectiveId = _x;
    if (_objectiveId == _hqObjectiveId) then { continue };
    if !(_objectiveId in FLO_Objectives) then { continue };

    private _nodeInfo = _activeNodes get _objectiveId;
    private _objective = FLO_Objectives get _objectiveId;

    _candidates pushBack (createHashMapFromArray [
        ["category", "supply_node"],
        ["revealKey", format ["SUPPLY_NODE|%1", _objectiveId]],
        ["alertType", "INTEL_SUPPLY_NODE"],
        ["objectiveId", _objectiveId],
        ["objectiveName", _objective get "name"],
        ["position", _objective get "position"],
        ["radius", ((_objective get "radius") max 140) min 400],
        ["duration", 300],
        ["priority", 1800 + ((_nodeInfo get "depth") * 100) + ((_nodeInfo get "deliveryCount") * 10) + (_objective get "priority")],
        ["message", format ["Recovered logistics traffic: enemy supply node identified at %1.", _objective get "name"]],
        ["payload", [
            _objective get "name",
            _nodeInfo get "depth",
            _enemyColor
        ]]
    ]);
} forEach (keys _activeNodes);

_candidates
