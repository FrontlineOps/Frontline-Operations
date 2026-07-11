/*
 * Function: FLO_fnc_minefieldRestoreSavedFields
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores tracked commander minefields from save payload data.
 *
 * Arguments:
 * 0: Saved field array <ARRAY>
 *
 * Return Value:
 * SCALAR
 */

params [
    ["_savedFields", [], [[]]]
];

if (!isServer) exitWith { 0 };

private _restoredCount = 0;
{
    if (!(_x isEqualType createHashMap)) then { continue };

    private _fieldId = _x get "id";
    private _objectiveId = _x get "objectiveId";
    if (_fieldId == "" || {_objectiveId == ""}) then { continue };

    private _sideKey = _x get "sideKey";
    private _side = if (_sideKey isEqualTo "WEST") then { west } else { east };
    if !(_objectiveId in FLO_Objectives) then { continue };
    if (_objectiveId in FLO_MinefieldObjectiveIndex) then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    if ((_objective get "owner") != _side) then { continue };

    private _mineObjects = [];
    {
        private _mineType = _x get "type";
        private _minePos = ASLToATL (_x get "posASL");
        private _mine = createMine [_mineType, _minePos, [], 0];
        if (isNull _mine) then { continue };
        _mine setVariable ["FLO_MinefieldId", _fieldId, false];
        _mine setVariable ["FLO_MinefieldObjectiveId", _objectiveId, false];
        _mine setVariable ["FLO_MineType", _mineType, false];
        _mineObjects pushBack _mine;
    } forEach (_x get "mineSpecs");

    if (_mineObjects isEqualTo []) then { continue };

    private _markerName = format ["FLO_MINEFIELD_%1", _fieldId];
    private _markerColor = ["ColorEAST", "ColorWEST"] select (_sideKey isEqualTo "WEST");
    if (getMarkerColor _markerName != "") then {
        deleteMarker _markerName;
    };
    private _minePositions = [];
    {
        _minePositions pushBack (getPosATL _x);
    } forEach _mineObjects;
    private _fieldGeometry = [(_x get "anchorPos"), (_x get "facingDir"), _minePositions] call FLO_fnc_minefieldCalculateFieldGeometry;
    private _fieldCenterPos = _fieldGeometry get "fieldCenterPos";
    private _depthHalfWidth = _fieldGeometry get "depthHalfWidth";
    private _frontageHalfWidth = _fieldGeometry get "frontageHalfWidth";

    private _marker = createMarker [_markerName, _fieldCenterPos];
    _marker setMarkerShapeLocal "RECTANGLE";
    _marker setMarkerBrushLocal "SolidBorder";
    _marker setMarkerColorLocal _markerColor;
    _marker setMarkerAlphaLocal (FLO_MinefieldConfig get "markerAlpha");
    _marker setMarkerDirLocal ((_x get "facingDir") + 90);
    _marker setMarkerPosLocal _fieldCenterPos;
    _marker setMarkerSizeLocal [_frontageHalfWidth, _depthHalfWidth];
    _marker setMarkerText "Minefield";

    private _field = createHashMapFromArray [
        ["id", _fieldId],
        ["objectiveId", _objectiveId],
        ["side", _side],
        ["sideKey", _sideKey],
        ["threatSignature", _x get "threatSignature"],
        ["centerPos", _x get "centerPos"],
        ["anchorPos", _x get "anchorPos"],
        ["fieldCenterPos", _fieldCenterPos],
        ["facingDir", _x get "facingDir"],
        ["depthHalfWidth", _depthHalfWidth],
        ["frontageHalfWidth", _frontageHalfWidth],
        ["packetSummaries", if ("packetSummaries" in _x) then { _x get "packetSummaries" } else { [] }],
        ["markerName", _markerName],
        ["mineObjects", _mineObjects]
    ];

    FLO_Minefields set [_fieldId, _field];
    FLO_MinefieldObjectiveIndex set [_objectiveId, _fieldId];
    _restoredCount = _restoredCount + 1;
} forEach _savedFields;

_restoredCount
