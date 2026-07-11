params [["_player", objNull, [objNull]]];

if (isNull _player) then { throw "FLO_fnc_objectiveDevelopmentBuildUiSnapshot: null player"; };
private _viewerSide = side group _player;
if !(_viewerSide in [west, east]) then {
    throw format ["FLO_fnc_objectiveDevelopmentBuildUiSnapshot: unsupported viewer side %1", _viewerSide];
};

private _sideKey = [_viewerSide] call FLO_fnc_sideKey;
private _treasury = FLO_SideResources get _sideKey;
private _economy = [_treasury] call FLO_fnc_sideResourcesGetUiSnapshot;
private _config = FLO_ObjectiveDevelopmentConfig;
private _maxLevels = _config get "maxLevelBySubtype";
private _sortedRows = [];

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") isNotEqualTo _viewerSide) then { continue };

    private _subtype = _objective get "subtype";
    private _maxLevel = _maxLevels get _subtype;
    if (_maxLevel == 0) then { continue };

    private _development = [_objectiveId, _objective, _viewerSide] call FLO_fnc_objectiveDevelopmentBuildSnapshot;
    private _name = [_objectiveId] call FLO_fnc_campaignObjectiveName;
    private _projectActive = (_development get "project") get "active";
    private _row = createHashMapFromArray [
        ["id", _objectiveId],
        ["name", _name],
        ["grid", mapGridPosition (_objective get "position")],
        ["position", _objective get "position"],
        ["subtype", _subtype],
        ["priority", _objective get "priority"],
        ["captureState", _objective get "captureState"],
        ["integrationState", _objective get "campaignIntegrationState"],
        ["contested", _objective get "contested"],
        ["underAttack", _objective get "underAttack"],
        ["development", _development]
    ];
    private _sortPrefix = ["1", "0"] select _projectActive;
    _sortedRows pushBack [format ["%1|%2|%3", _sortPrefix, toLower _name, _objectiveId], _row];
} forEach (keys FLO_Objectives);

_sortedRows sort true;
private _objectiveRows = _sortedRows apply { _x select 1 };
private _tierRows = [];
{
    private _tier = [_x] call FLO_fnc_objectiveDevelopmentGetTier;
    _tierRows pushBack createHashMapFromArray [
        ["level", _x],
        ["name", _tier get "name"],
        ["treasuryCost", _tier get "treasuryCost"],
        ["supplyRequired", _tier get "supplyRequired"],
        ["playerSupplyCap", _tier get "playerSupplyCap"],
        ["incomeMultiplier", _tier get "incomeMultiplier"]
    ];
} forEach [0, 1, 2, 3];

private _activeIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
createHashMapFromArray [
    ["generatedAt", diag_tickTime],
    ["sideKey", _sideKey],
    ["sideName", ["BLUFOR", "OPFOR"] select (_viewerSide isEqualTo east)],
    ["keybind", "Ctrl+Shift+I"],
    ["economy", _economy],
    ["activeCount", count _activeIds],
    ["maximumConcurrentProjects", _config get "maximumConcurrentProjects"],
    ["tickInterval", _config get "tickInterval"],
    ["commanderSupplyPerTick", _config get "commanderSupplyPerTick"],
    ["playerContributionPercent", round ((_config get "playerContributionFraction") * 100)],
    ["assignmentRadius", _config get "assignmentRadius"],
    ["tiers", _tierRows],
    ["objectives", _objectiveRows]
]
