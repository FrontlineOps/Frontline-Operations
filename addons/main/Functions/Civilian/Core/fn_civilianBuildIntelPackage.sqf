/*
 * Function: FLO_fnc_civilianBuildIntelPackage
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds one contextual civilian intel package using maintained GTN enemy
 *   known hostile-group picture and local objective context.
 *
 * Arguments:
 * 0: Civilian position <ARRAY>
 * 1: Objective ID <STRING>
 * 2: Reporting side <SIDE>
 * 3: Civilian role <STRING>
 * 4: Knowledge bias <NUMBER>
 *
 * Return Value:
 * HASHMAP - Empty on failure, otherwise alert package
 */

params [
    ["_civilianPos", [0, 0, 0], [[]], [3]],
    ["_objectiveId", "", [""]],
    ["_reportingSide", west, [east]],
    ["_civilianRole", "resident", [""]],
    ["_knowledgeBias", 1, [0]]
];

private _package = createHashMap;
if (_objectiveId == "") exitWith { _package };
if !(_reportingSide in [east, west]) exitWith { _package };

if (!isNil "FLO_CivilianManager") then {
    private _memory = [
        FLO_CivilianManager get "_objectiveMemories",
        _objectiveId,
        _civilianRole,
        diag_tickTime
    ] call FLO_fnc_civilianSelectObjectiveMemory;

    if ((keys _memory) isNotEqualTo []) exitWith {
        [_memory, _reportingSide, _civilianRole] call FLO_fnc_civilianBuildIntelPackageFromMemory
    };
};

private _commander = [_reportingSide] call FLO_fnc_gtnGetCommanderBySide;
if (isNil "_commander") exitWith { _package };

private _worldState = _commander get "_worldState";
private _knownGroupPicture = _worldState call ["_getKnownEnemyGroupPicture", []];
private _knownGroups = _knownGroupPicture get "groups";
private _objectiveGroups = _knownGroupPicture get "objectiveGroups";
private _candidateIds = +(_objectiveGroups getOrDefault [_objectiveId, []]);

if (_candidateIds isEqualTo []) then {
    {
        private _target = _knownGroups get _x;
        if ((_target get "position") distance2D _civilianPos > (FLO_CivilianConfig get "MAX_LOCAL_INTEL_RADIUS")) then { continue };
        _candidateIds pushBack _x;
    } forEach (keys _knownGroups);
};

private _selectedTarget = createHashMap;
private _bestDistance = 1e12;
{
    private _target = _knownGroups get _x;
    if (isNil "_target") then { continue };

    private _distance = _civilianPos distance2D (_target get "position");
    if (_distance < _bestDistance) then {
        _bestDistance = _distance;
        _selectedTarget = _target;
    };
} forEach _candidateIds;

if ((keys _selectedTarget) isNotEqualTo []) then {
    private _targetPos = _selectedTarget get "position";
    private _targetType = _selectedTarget get "groupType";
    private _targetOrder = _selectedTarget get "commanderOrder";
    private _packageType = switch (true) do {
        case (_civilianRole == "driver" && {_targetType in ["armor", "mechanized", "motorized", "mobile_aa"]}): { "VEHICLE_MOVEMENT" };
        case (_targetOrder in ["GARRISON", "DEFEND"]): { "CHECKPOINT_RUMOR" };
        case (_civilianRole in ["watcher", "vendor"]): { "PATROL_SIGHTING" };
        default { "HOSTILE_REPORT" };
    };

    private _uncertainty = (1.2 - (_knowledgeBias min 1.15)) max 0.2;
    private _radius = switch (_packageType) do {
        case "VEHICLE_MOVEMENT": { 260 + round (_uncertainty * 220) };
        case "CHECKPOINT_RUMOR": { 320 + round (_uncertainty * 260) };
        default { 220 + round (_uncertainty * 180) };
    };
    private _duration = switch (_packageType) do {
        case "CHECKPOINT_RUMOR": { 180 };
        case "VEHICLE_MOVEMENT": { 120 };
        default { 90 };
    };
    private _message = switch (_packageType) do {
        case "VEHICLE_MOVEMENT": { format ["Civilian report: military vehicles were seen near grid %1", mapGridPosition _targetPos] };
        case "CHECKPOINT_RUMOR": { format ["Civilian rumor: hostile checkpoint activity near grid %1", mapGridPosition _targetPos] };
        case "PATROL_SIGHTING": { format ["Civilian report: armed patrol seen near grid %1", mapGridPosition _targetPos] };
        default { format ["Civilian report: hostile activity near grid %1", mapGridPosition _targetPos] };
    };

    _package = createHashMapFromArray [
        ["reportingSide", _reportingSide],
        ["position", _targetPos],
        ["radius", _radius],
        ["duration", _duration],
        ["message", _message],
        ["payload", [_packageType, _knowledgeBias]]
    ];
    _package
} else {
    if !(_objectiveId in FLO_Objectives) exitWith { _package };

    private _objective = FLO_Objectives get _objectiveId;
    private _objectivePos = _objective get "position";
    private _objectiveContested = _objective get "contested";
    private _packageType = ["SAFE_ROUTE_HINT", "HOSTILE_REPORT"] select (_objectiveContested);
    private _message = if (_packageType == "SAFE_ROUTE_HINT") then {
        format ["Civilian tip: roads near grid %1 seem quiet for now", mapGridPosition _objectivePos]
    } else {
        format ["Civilian report: tension remains high near grid %1", mapGridPosition _objectivePos]
    };

    createHashMapFromArray [
        ["reportingSide", _reportingSide],
        ["position", _objectivePos],
        ["radius", [320, 180] select (_packageType == "SAFE_ROUTE_HINT")],
        ["duration", [120, 75] select (_packageType == "SAFE_ROUTE_HINT")],
        ["message", _message],
        ["payload", [_packageType, _knowledgeBias]]
    ]
}
