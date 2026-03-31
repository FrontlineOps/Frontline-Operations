/*
 * Function: FLO_fnc_civilianBuildMissionOffer
 * Author: Frontline Operations Development Group
 * Description:
 *   Scores and selects one civilian mission offer from local context,
 *   linked-objective pressure, and remembered civilian incidents.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 * 1: Caller <OBJECT>
 * 2: Civilian virtual group data <HASHMAP>
 *
 * Return Value:
 * HASHMAP - Mission offer, empty on refusal
 */

params [
    ["_civilian", objNull, [objNull]],
    ["_caller", objNull, [objNull]],
    ["_groupData", createHashMap, [createHashMap]]
];

private _offer = createHashMap;
if (isNull _civilian || {isNull _caller}) exitWith { _offer };

private _callerSide = side group _caller;
if !(_callerSide in [east, west]) then {
    _callerSide = FLO_ActivePlayerSide;
};
if !(_callerSide in [east, west]) exitWith { _offer };

private _objectiveId = if ((count (keys _groupData)) > 0) then {
    _groupData get "civilianObjective"
} else {
    _civilian getVariable ["FLO_CivilianObjective", ""]
};
if (_objectiveId == "") then {
    _objectiveId = [getPosATL _civilian] call FLO_fnc_civilianResolveObjective;
};
if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) exitWith { _offer };

private _role = if ((count (keys _groupData)) > 0) then {
    _groupData get "civilianRole"
} else {
    _civilian getVariable ["FLO_CivilianRole", "resident"]
};

private _context = if (!isNil "FLO_CivilianManager") then {
    FLO_CivilianManager call ["getObjectiveContext", [_objectiveId, _role, _callerSide]]
} else {
    [_objectiveId, _role, _callerSide] call FLO_fnc_civilianResolveObjectiveContext
};

private _disposition = _context get "disposition";
if (_disposition == "HOSTILE") exitWith { _offer };

private _objective = FLO_Objectives get _objectiveId;
private _linkedObjectives = _objective get "linkedObjectives";
private _enemyLinkedObjectives = [];
{
    private _linkedObjective = FLO_Objectives get _x;
    private _owner = _linkedObjective get "owner";
    if (_owner in [east, west] && {_owner != _callerSide}) then {
        _enemyLinkedObjectives pushBack _x;
    };
} forEach _linkedObjectives;

private _memory = if (!isNil "FLO_CivilianManager") then {
    [
        FLO_CivilianManager get "_objectiveMemories",
        _objectiveId,
        _role,
        diag_tickTime
    ] call FLO_fnc_civilianSelectObjectiveMemory
} else {
    createHashMap
};
private _memoryType = if ((count (keys _memory)) > 0) then { _memory get "reportType" } else { "" };

private _securityObjectiveId = _objectiveId;
if ((count (keys _memory)) > 0) then {
    _securityObjectiveId = _memory get "sourceObjectiveId";
} else {
    if ((count _enemyLinkedObjectives) > 0) then {
        _securityObjectiveId = _enemyLinkedObjectives select 0;
    };
};
if (_securityObjectiveId == "") then {
    _securityObjectiveId = _objectiveId;
};

private _objectiveName = _objective get "name";
if (_objectiveName == "") then {
    _objectiveName = "this town";
};

private _securityObjective = FLO_Objectives get _securityObjectiveId;
private _securityObjectiveName = _securityObjective get "name";
if (_securityObjectiveName == "") then {
    _securityObjectiveName = "the nearby roads";
};

private _frontlinePressure = (_objective get "contested") || {(count _enemyLinkedObjectives) > 0};

private _repairScore = 0.15;
if !(_objective get "contested") then { _repairScore = _repairScore + 0.3; };
if (_disposition in ["NEUTRAL", "FRIENDLY"]) then { _repairScore = _repairScore + 0.25; };
if ((count _enemyLinkedObjectives) == 0) then { _repairScore = _repairScore + 0.2; };
if (_memoryType in ["", "PATROL_SIGHTING", "SAFE_ROUTE_HINT"]) then { _repairScore = _repairScore + 0.1; };
if (_role in ["worker", "driver", "resident"]) then { _repairScore = _repairScore + 0.05; };

private _deliverScore = 0.2;
if (_disposition in ["NEUTRAL", "FRIENDLY"]) then { _deliverScore = _deliverScore + 0.25; };
if !(_objective get "contested") then { _deliverScore = _deliverScore + 0.15; };
if !(_memoryType in ["HOSTILE_REPORT", "CHECKPOINT_RUMOR"]) then { _deliverScore = _deliverScore + 0.1; };
if (_role in ["vendor", "worker", "resident"]) then { _deliverScore = _deliverScore + 0.1; };

private _mineScore = 0.05;
if (_frontlinePressure) then { _mineScore = _mineScore + 0.2; };
if (_memoryType in ["CHECKPOINT_RUMOR", "HOSTILE_REPORT"]) then { _mineScore = _mineScore + 0.35; };
if (_role in ["watcher", "driver"]) then { _mineScore = _mineScore + 0.1; };
if (_securityObjectiveId != _objectiveId) then { _mineScore = _mineScore + 0.05; };

private _checkpointScore = 0.05;
if (_frontlinePressure) then { _checkpointScore = _checkpointScore + 0.3; };
if ((count _enemyLinkedObjectives) > 0) then { _checkpointScore = _checkpointScore + 0.2; };
if (_memoryType in ["CHECKPOINT_RUMOR", "HOSTILE_REPORT"]) then { _checkpointScore = _checkpointScore + 0.25; };
if (_role in ["watcher", "vendor"]) then { _checkpointScore = _checkpointScore + 0.05; };

private _offers = [
    createHashMapFromArray [
        ["missionType", "repair_vehicle"],
        ["templateFunction", "civMission1"],
        ["score", _repairScore],
        ["targetObjectiveId", _objectiveId],
        ["taskTitle", "Repair Vehicle"],
        ["briefing", format ["A local from %1 has a broken civilian vehicle on the roads nearby.", _objectiveName]],
        ["requestLine", "One of our people is stranded on the road. Can your engineers get the vehicle moving again?"]
    ],
    createHashMapFromArray [
        ["missionType", "deliver_supplies"],
        ["templateFunction", "civMission2"],
        ["score", _deliverScore],
        ["targetObjectiveId", _objectiveId],
        ["taskTitle", "Deliver Supplies"],
        ["briefing", format ["Families in %1 need supplies delivered deeper into town.", _objectiveName]],
        ["requestLine", "We need supplies moved through town. If you can carry them, people here will remember it."]
    ],
    createHashMapFromArray [
        ["missionType", "clear_minefield"],
        ["templateFunction", "civMission3"],
        ["score", _mineScore],
        ["targetObjectiveId", _securityObjectiveId],
        ["taskTitle", "Clear Minefield"],
        ["briefing", format ["Civilians report that the roads around %1 are unsafe and may be mined.", _securityObjectiveName]],
        ["requestLine", "People are afraid to use the roads near there. Can your engineers clear whatever was left behind?"]
    ],
    createHashMapFromArray [
        ["missionType", "establish_checkpoint"],
        ["templateFunction", "civMission4"],
        ["score", _checkpointScore],
        ["targetObjectiveId", _securityObjectiveId],
        ["taskTitle", "Establish Checkpoint"],
        ["briefing", format ["Movement around %1 is being harassed by armed men.", _securityObjectiveName]],
        ["requestLine", "If you hold the road there, people here might move safely again."]
    ]
];

private _minimumScore = if (_disposition == "WARY") then { 0.55 } else { 0.45 };
private _viableOffers = _offers select { (_x get "score") >= _minimumScore };
if ((count _viableOffers) == 0) exitWith { _offer };

_viableOffers = [_viableOffers, [], { _x get "score" }, "DESCEND"] call BIS_fnc_sortBy;
_offer = _viableOffers select 0;
_offer set ["missionId", format ["CivMission_%1_%2", toUpper (_offer get "missionType"), floor random 100000]];
_offer set ["objectiveId", _objectiveId];
_offer set ["caller", _caller];
_offer set ["callerSide", _callerSide];
_offer set ["civilian", _civilian];
_offer set ["civilianRole", _role];
_offer set ["contextDisposition", _disposition];
_offer set ["memoryType", _memoryType];

_offer
