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
private _sortedRows = [];

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") isNotEqualTo _viewerSide) then { continue };

    private _development = [_objectiveId, _objective, _viewerSide] call FLO_fnc_objectiveDevelopmentBuildSnapshot;
    private _name = [_objectiveId] call FLO_fnc_campaignObjectiveName;
    private _projectActive = (_development get "project") get "active";
    private _row = createHashMapFromArray [
        ["id", _objectiveId],
        ["name", _name],
        ["grid", mapGridPosition (_objective get "position")],
        ["position", _objective get "position"],
        ["subtype", _objective get "subtype"],
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
private _revenuePreview = [];
private _developmentPreview = [];
{
    _revenuePreview pushBack createHashMapFromArray [
        ["level", _x],
        ["multiplier", [_x] call FLO_fnc_objectiveDevelopmentRevenueMultiplier]
    ];
    _developmentPreview pushBack createHashMapFromArray [
        ["level", _x],
        ["discountPercent", round (([_x] call FLO_fnc_objectiveDevelopmentDiscount) * 100)]
    ];
} forEach [0, 1, 3, 6, 10];

private _activeIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
private _projectCapacity = [_viewerSide] call FLO_fnc_objectiveDevelopmentGetProjectCapacity;
private _totalDevelopmentLevels = [_viewerSide] call FLO_fnc_objectiveDevelopmentGetTotalDevelopmentLevels;
private _capacityBonus = _projectCapacity - (_config get "baseProjectSlots");
private _nextCapacityLevel = (_config get "projectSlotDivisor") * (_capacityBonus + 1) * (_capacityBonus + 1);
createHashMapFromArray [
    ["generatedAt", diag_tickTime],
    ["sideKey", _sideKey],
    ["sideName", ["BLUFOR", "OPFOR"] select (_viewerSide isEqualTo east)],
    ["keybind", "Ctrl+Shift+I"],
    ["economy", _economy],
    ["activeCount", count _activeIds],
    ["projectCapacity", _projectCapacity],
    ["totalDevelopmentLevels", _totalDevelopmentLevels],
    ["nextCapacityLevel", _nextCapacityLevel],
    ["levelsToNextCapacity", (_nextCapacityLevel - _totalDevelopmentLevels) max 0],
    ["tickInterval", _config get "tickInterval"],
    ["investmentInterval", _config get "investmentInterval"],
    ["commanderSupplyPerTick", _config get "commanderSupplyPerTick"],
    ["playerContributionPercent", round ((_config get "playerContributionFraction") * 100)],
    ["assignmentRadius", _config get "assignmentRadius"],
    ["captureRetentionPercent", round ((_config get "captureRetention") * 100)],
    ["revenuePaybackCycles", _config get "revenuePaybackCycles"],
    ["developmentBaseCost", _config get "developmentBaseCost"],
    ["revenuePreview", _revenuePreview],
    ["developmentPreview", _developmentPreview],
    ["objectives", _objectiveRows]
]
