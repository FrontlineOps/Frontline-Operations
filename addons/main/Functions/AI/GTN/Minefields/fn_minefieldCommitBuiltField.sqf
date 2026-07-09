/*
 * Function: FLO_fnc_minefieldCommitBuiltField
 * Author: Frontline Operations Development Group
 * Description:
 *   Commits a fully-built queued minefield job into the live field registry.
 *
 * Arguments:
 * 0: Build job <HASHMAP>
 *
 * Return Value:
 * STRING - "PLACED" on success, otherwise failure reason
 */

params [["_job", createHashMap]];

if (!(_job isEqualType createHashMap)) exitWith { "INVALID_JOB" };

private _metrics = _job get "metrics";
private _tCommit = diag_tickTime;
private _context = _job get "context";
private _fieldId = _job get "fieldId";
private _objectiveId = _job get "objectiveId";
private _mineObjects = _job get "mineObjects";
private _selectedMinePositions = _job get "selectedMinePositions";
private _resourceObj = FLO_SideResources get (_job get "sideKey");
private _spendType = FLO_MinefieldConfig get "resourceSpendType";
private _spentBaseAmount = (count _mineObjects) * (FLO_MinefieldConfig get "resourceCostPerMine");
private _spentResources = ([_resourceObj, _spentBaseAmount, _spendType] call FLO_fnc_sideResourcesCalculateCost) select 0;

if !([_resourceObj, _spentBaseAmount, _spendType] call FLO_fnc_sideResourcesSpendResources) exitWith {
    _metrics set ["reason", "RESOURCE_SPEND_FAILED"];
    "RESOURCE_SPEND_FAILED"
};

private _fieldGeometry = [(_context get "anchorPos"), (_context get "facingDir"), _selectedMinePositions] call FLO_fnc_minefieldCalculateFieldGeometry;
private _fieldCenterPos = _fieldGeometry get "fieldCenterPos";
private _depthHalfWidth = _fieldGeometry get "depthHalfWidth";
private _frontageHalfWidth = _fieldGeometry get "frontageHalfWidth";
private _markerName = format ["FLO_MINEFIELD_%1", _fieldId];
private _markerColor = ["ColorWEST", "ColorEAST"] select ((_job get "sideKey") isEqualTo "EAST");

if (getMarkerColor _markerName != "") then {
    deleteMarker _markerName;
};

private _marker = createMarker [_markerName, _fieldCenterPos];
_marker setMarkerShapeLocal "RECTANGLE";
_marker setMarkerBrushLocal "SolidBorder";
_marker setMarkerColorLocal _markerColor;
_marker setMarkerAlphaLocal (FLO_MinefieldConfig get "markerAlpha");
_marker setMarkerDirLocal ((_context get "facingDir") + 90);
_marker setMarkerPosLocal _fieldCenterPos;
_marker setMarkerSizeLocal [_frontageHalfWidth, _depthHalfWidth];
_marker setMarkerText "Minefield";

private _field = createHashMapFromArray [
    ["id", _fieldId],
    ["objectiveId", _objectiveId],
    ["side", _job get "side"],
    ["sideKey", _job get "sideKey"],
    ["threatSignature", _job get "threatSignature"],
    ["centerPos", _context get "objectivePos"],
    ["anchorPos", _context get "anchorPos"],
    ["fieldCenterPos", _fieldCenterPos],
    ["facingDir", _context get "facingDir"],
    ["depthHalfWidth", _depthHalfWidth],
    ["frontageHalfWidth", _frontageHalfWidth],
    ["layerCount", _metrics get "layerCount"],
    ["packetSummaries", _job get "packets"],
    ["markerName", _markerName],
    ["mineObjects", _mineObjects]
];

FLO_Minefields set [_fieldId, _field];
FLO_MinefieldObjectiveIndex set [_objectiveId, _fieldId];
_metrics set ["commitMs", (_metrics get "commitMs") + ((diag_tickTime - _tCommit) * 1000)];
_metrics set ["spentResources", _spentResources];
_metrics set ["reason", "PLACED"];

["MINEFIELD", 3, format [
    "%1 commander laid objective minefield %2 at %3 with %4/%5 mines packets=%6 layers=%7 spent=%8 resourcesNow=%9",
    _job get "sideKey",
    _objectiveId,
    mapGridPosition (_context get "anchorPos"),
    count _mineObjects,
    _metrics get "plannedMineCount",
    _metrics get "packetCount",
    _metrics get "layerCount",
    _metrics get "spentResources",
    _resourceObj get "_resources"
]] call FLO_fnc_log;

"PLACED"
