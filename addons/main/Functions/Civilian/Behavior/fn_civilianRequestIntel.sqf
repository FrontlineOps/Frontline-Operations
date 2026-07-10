/*
 * Function: FLO_fnc_civilianRequestIntel
 * Author: Frontline Operations Development Group
 * Description:
 *   Handles an intel request against one civilian using the rewritten
 *   role-based civilian context model.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 * 1: Caller <OBJECT>
 *
 * Return Value:
 * BOOL - True when a useful interaction resolved
 */

params [
    ["_civilian", objNull, [objNull]],
    ["_caller", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_civilian, _caller] remoteExecCall ["FLO_fnc_civilianRequestIntel", 2, false];
    false
};

if (isNull _civilian || {isNull _caller} || {!alive _civilian} || {!alive _caller}) exitWith { false };

private _callerSide = side group _caller;
if !(_callerSide in [east, west]) then {
    _callerSide = FLO_ActivePlayerSide;
};
if !(_callerSide in [east, west]) exitWith { false };

private _groupId = _civilian getVariable ["FLO_VirtualGroupId", ""];
private _groupData = if (_groupId != "") then {
    private _snapshot = [_groupId] call FLO_fnc_virtualizationFindGroupSnapshot;
    if (isNil "_snapshot") then { createHashMap } else { _snapshot }
} else {
    createHashMap
};

private _objectiveId = if ((keys _groupData) isNotEqualTo []) then {
    _groupData get "civilianObjective"
} else {
    _civilian getVariable ["FLO_CivilianObjective", ""]
};
if (_objectiveId == "") then {
    _objectiveId = [getPosATL _civilian] call FLO_fnc_civilianResolveObjective;
};

private _civilianRole = if ((keys _groupData) isNotEqualTo []) then {
    _groupData get "civilianRole"
} else {
    _civilian getVariable ["FLO_CivilianRole", "resident"]
};
private _trustBias = if ((keys _groupData) isNotEqualTo []) then { _groupData get "civilianTrustBias" } else { 1 };
private _knowledgeBias = if ((keys _groupData) isNotEqualTo []) then { _groupData get "civilianKnowledgeBias" } else { 1 };
private _lastIntelAt = if ((keys _groupData) isNotEqualTo []) then { _groupData get "civilianLastIntelAt" } else { -1 };

private _context = if (!isNil "FLO_CivilianManager") then {
    FLO_CivilianManager call ["getObjectiveContext", [_objectiveId, _civilianRole, _callerSide]]
} else {
    [_objectiveId, _civilianRole, _callerSide] call FLO_fnc_civilianResolveObjectiveContext
};
private _intelCooldown = FLO_CivilianConfig get "INTEL_COOLDOWN_SECONDS";
private _callerOwner = owner _caller;

if (_lastIntelAt >= 0 && {(diag_tickTime - _lastIntelAt) < _intelCooldown}) exitWith {
    ["Civilian", selectRandom [
        "I already told you what I know.",
        "That is all I have heard for now.",
        "Come back later if I hear more."
    ]] remoteExec ["BIS_fnc_showSubtitle", _callerOwner, false];
    false
};

private _hostileRoll = random 1;
private _hostileChance = ((_context get "hostileReportChance") * (2 - _trustBias)) min 0.95;
if (_hostileRoll < _hostileChance) exitWith {
    [_civilian, _groupId] call FLO_fnc_civilianRecordIntelInteraction;

    private _enemySide = if (_callerSide isEqualTo west) then { east } else { west };
    private _package = createHashMapFromArray [
        ["reportingSide", _enemySide],
        ["position", getPosATL _caller],
        ["radius", 300],
        ["duration", 90],
        ["message", format ["Civilian report: armed outsiders seen near grid %1", mapGridPosition (getPosATL _caller)]],
        ["payload", ["HOSTILE_REPORT", 0.35]]
    ];
    [_package] call FLO_fnc_gtnAlertCivilianReport;
    ["Civilian", selectRandom [
        "Leave me alone.",
        "I do not trust you.",
        "You should not be asking questions here."
    ]] remoteExec ["BIS_fnc_showSubtitle", _callerOwner, false];
    false
};

private _intelChance = (((_context get "intelChance") * _knowledgeBias) * _trustBias) min 0.95;
if ((random 1) > _intelChance) exitWith {
    [_civilian, _groupId] call FLO_fnc_civilianRecordIntelInteraction;

    ["Civilian", selectRandom [
        "I have not seen anything useful.",
        "I do not know enough to help you.",
        "People keep their heads down around here."
    ]] remoteExec ["BIS_fnc_showSubtitle", _callerOwner, false];
    false
};

private _package = [getPosATL _civilian, _objectiveId, _callerSide, _civilianRole, _knowledgeBias] call FLO_fnc_civilianBuildIntelPackage;
if ((keys _package) isEqualTo []) exitWith {
    [_civilian, _groupId] call FLO_fnc_civilianRecordIntelInteraction;

    ["Civilian", selectRandom [
        "Nothing worth telling you right now.",
        "The streets are quiet from what I know.",
        "I have heard no useful rumor."
    ]] remoteExec ["BIS_fnc_showSubtitle", _callerOwner, false];
    false
};

private _intelCost = _context get "intelCost";
private _sideKey = [_callerSide] call FLO_fnc_sideKey;
private _treasury = FLO_SideResources get _sideKey;
if !([_treasury, _intelCost] call FLO_fnc_sideResourcesCanAfford) exitWith {
    [["Need %1 resources to compensate the civilian contact.", _intelCost], "warning", false, _callerOwner] call FLO_fnc_sendNotification;
    false
};

if !([
    _treasury,
    _intelCost,
    "INTELLIGENCE",
    format ["Civilian intelligence near %1", _objectiveId],
    name _caller,
    _objectiveId,
    true
] call FLO_fnc_sideResourcesSpendResources) then {
    throw "Civilian intelligence affordability changed during an unscheduled server transaction";
};

[_civilian, _groupId] call FLO_fnc_civilianRecordIntelInteraction;

[_package] call FLO_fnc_gtnAlertCivilianReport;
["Civilian", [_package] call FLO_fnc_civilianBuildIntelSubtitle] remoteExec ["BIS_fnc_showSubtitle", _callerOwner, false];

true
