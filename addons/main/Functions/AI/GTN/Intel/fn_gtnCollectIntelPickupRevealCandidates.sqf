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

private _enemyCommander = [_enemySide] call FLO_fnc_gtnGetCommanderBySide;
if (isNil "_enemyCommander") exitWith { _candidates };

private _assignmentCache = _enemyCommander get "_objectiveAssignmentCache";
private _attackCounts = _assignmentCache get "attackCounts";

{
    private _objectiveId = _x;
    private _attackerCount = _y;
    if !(_objectiveId in FLO_Objectives) then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") != _playerSide) then { continue };

    _candidates pushBack (createHashMapFromArray [
        ["category", "commander_target"],
        ["revealKey", format ["COMMANDER_TARGET|%1", _objectiveId]],
        ["alertType", "INTEL_COMMANDER_TARGET"],
        ["objectiveId", _objectiveId],
        ["objectiveName", _objective get "name"],
        ["position", _objective get "position"],
        ["radius", ((_objective get "radius") max 150) min 450],
        ["duration", 300],
        ["priority", 3000 + (_attackerCount * 50) + (_objective get "priority")],
        ["message", format ["Recovered enemy comms: %1 attack groups ordered toward %2.", _attackerCount, _objective get "name"]],
        ["payload", [
            _objective get "name",
            format ["ATTACK x%1", _attackerCount],
            _enemyColor
        ]]
    ]);
} forEach _attackCounts;

private _enemyNetwork = FLO_Logistics_Networks get _enemySideKey;
[_enemyNetwork] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _enemyNodes = _enemyNetwork get "_nodes";

{
    private _nodeId = _x;
    private _node = _y;
    private _nodeState = _node get "state";
    if (_nodeState == "DISABLED") then { continue };

    private _nodeType = _node get "type";
    private _position = +(_node get "position");
    private _objectiveId = _node get "objectiveId";
    private _objectiveName = format ["GRID %1", mapGridPosition _position];
    private _objectivePriority = 0;
    private _radius = 220;
    if (_objectiveId != "" && {_objectiveId in FLO_Objectives}) then {
        private _objective = FLO_Objectives get _objectiveId;
        _objectiveName = _objective get "name";
        _objectivePriority = _objective get "priority";
        _radius = ((_objective get "radius") max 140) min 500;
    };

    private _isHQ = _nodeType == "HQ";
    private _category = ["supply_node", "hq"] select _isHQ;
    private _alertType = ["INTEL_SUPPLY_NODE", "INTEL_HQ"] select _isHQ;
    private _duration = [300, 420] select _isHQ;
    private _priority = switch (_nodeType) do {
        case "HQ": { 2400 };
        case "DEPOT": { 2100 };
        case "FOB": { 1800 };
        default { 1500 };
    };
    private _message = if (_isHQ) then {
        format ["Recovered enemy command data: HQ identified near %1.", _objectiveName]
    } else {
        format ["Recovered logistics traffic: enemy %1 identified near %2.", toLower _nodeType, _objectiveName]
    };

    _candidates pushBack (createHashMapFromArray [
        ["category", _category],
        ["revealKey", format [["SUPPLY_NODE|%1", "HQ|%1"] select _isHQ, _nodeId]],
        ["alertType", _alertType],
        ["nodeType", _nodeType],
        ["objectiveId", _objectiveId],
        ["objectiveName", _objectiveName],
        ["position", _position],
        ["radius", _radius],
        ["duration", _duration],
        ["priority", _priority + _objectivePriority],
        ["message", _message],
        ["payload", [
            _objectiveName,
            _nodeType,
            _enemyColor
        ]]
    ]);
} forEach _enemyNodes;

_candidates
