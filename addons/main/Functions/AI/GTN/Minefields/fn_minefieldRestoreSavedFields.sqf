/*
 * Function: FLO_fnc_minefieldRestoreSavedFields
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores exact current-version minefield state atomically.
 *
 * Arguments:
 * 0: Saved field array <ARRAY>
 * 1: Saved objective cooldowns <HASHMAP>
 *
 * Return Value:
 * SCALAR
 */

params ["_savedFields", "_savedCooldowns"];

if (!isServer) exitWith { 0 };

if !(_savedFields isEqualType []) then {
    throw format ["Minefield records have invalid type %1", typeName _savedFields];
};
if !(_savedCooldowns isEqualType createHashMap) then {
    throw format ["Minefield objective cooldowns have invalid type %1", typeName _savedCooldowns];
};
if ((keys FLO_Minefields) isNotEqualTo []) then {
    throw "Minefield restore requires an empty field registry";
};
if ((keys FLO_MinefieldObjectiveIndex) isNotEqualTo []) then {
    throw "Minefield restore requires an empty objective index";
};
if ((keys FLO_MinefieldObjectiveCooldowns) isNotEqualTo []) then {
    throw "Minefield restore requires an empty cooldown registry";
};

private _validatedFields = [];
private _validatedFieldIds = createHashMap;
private _validatedObjectiveIds = createHashMap;
{
    private _savedField = _x;
    [_savedField, _forEachIndex] call FLO_fnc_minefieldValidateSavedField;

    private _fieldId = _savedField get "id";
    private _objectiveId = _savedField get "objectiveId";
    if (_fieldId in _validatedFieldIds) then {
        throw format ["Duplicate minefield id %1", _fieldId];
    };
    if (_objectiveId in _validatedObjectiveIds) then {
        throw format ["Objective %1 owns multiple saved minefields", _objectiveId];
    };

    _validatedFieldIds set [_fieldId, true];
    _validatedObjectiveIds set [_objectiveId, true];
    _validatedFields pushBack _savedField;
} forEach _savedFields;

private _validatedCooldowns = createHashMap;
{
    private _objectiveId = _x;
    private _cooldownUntil = _y;
    if !(_objectiveId isEqualType "") then {
        throw format ["Minefield cooldown objective id has invalid type %1", typeName _objectiveId];
    };
    if (_objectiveId == "") then {
        throw "Minefield cooldown has an empty objective id";
    };
    if !(_objectiveId in FLO_Objectives) then {
        throw format ["Minefield cooldown references missing objective %1", _objectiveId];
    };
    if !(_cooldownUntil isEqualType 0) then {
        throw format ["Minefield cooldown for %1 has invalid type %2", _objectiveId, typeName _cooldownUntil];
    };
    _validatedCooldowns set [_objectiveId, _cooldownUntil];
} forEach _savedCooldowns;

private _stagedFields = createHashMap;
private _stagedObjectiveIndex = createHashMap;
private _createdMines = [];
private _createdMarkers = [];
private _buildError = "";
try {
    {
        private _savedField = _x;
        private _fieldId = _savedField get "id";
        private _objectiveId = _savedField get "objectiveId";
        private _sideKey = _savedField get "sideKey";
        private _side = [east, west] select (_sideKey isEqualTo "WEST");

        private _mineObjects = [];
        {
            private _mineType = _x get "type";
            private _minePos = ASLToATL (_x get "posASL");
            private _mine = createMine [_mineType, _minePos, [], 0];
            if (isNull _mine) then {
                throw format ["Minefield %1 could not create mine %2", _fieldId, _forEachIndex];
            };
            _mine setVariable ["FLO_MinefieldId", _fieldId, false];
            _mine setVariable ["FLO_MinefieldObjectiveId", _objectiveId, false];
            _mine setVariable ["FLO_MineType", _mineType, false];
            _mineObjects pushBack _mine;
            _createdMines pushBack _mine;
        } forEach (_savedField get "mineSpecs");

        private _markerName = format ["FLO_MINEFIELD_%1", _fieldId];
        if (getMarkerColor _markerName != "") then {
            throw format ["Minefield %1 marker %2 already exists", _fieldId, _markerName];
        };

        private _minePositions = [];
        {
            _minePositions pushBack (getPosATL _x);
        } forEach _mineObjects;
        private _fieldGeometry = [
            _savedField get "anchorPos",
            _savedField get "facingDir",
            _minePositions
        ] call FLO_fnc_minefieldCalculateFieldGeometry;
        if ((keys _fieldGeometry) isEqualTo []) then {
            throw format ["Minefield %1 could not rebuild field geometry", _fieldId];
        };
        private _fieldCenterPos = _fieldGeometry get "fieldCenterPos";
        private _depthHalfWidth = _fieldGeometry get "depthHalfWidth";
        private _frontageHalfWidth = _savedField get "frontageHalfWidth";
        private _markerColor = ["ColorEAST", "ColorWEST"] select (_sideKey isEqualTo "WEST");

        private _marker = createMarker [_markerName, _fieldCenterPos];
        _createdMarkers pushBack _marker;
        _marker setMarkerShapeLocal "RECTANGLE";
        _marker setMarkerBrushLocal "SolidBorder";
        _marker setMarkerColorLocal _markerColor;
        _marker setMarkerAlphaLocal (FLO_MinefieldConfig get "markerAlpha");
        _marker setMarkerDirLocal ((_savedField get "facingDir") + 90);
        _marker setMarkerPosLocal _fieldCenterPos;
        _marker setMarkerSizeLocal [_frontageHalfWidth, _depthHalfWidth];
        _marker setMarkerText "Minefield";

        private _field = createHashMapFromArray [
            ["id", _fieldId],
            ["objectiveId", _objectiveId],
            ["side", _side],
            ["sideKey", _sideKey],
            ["threatSignature", _savedField get "threatSignature"],
            ["centerPos", _savedField get "centerPos"],
            ["anchorPos", _savedField get "anchorPos"],
            ["fieldCenterPos", _fieldCenterPos],
            ["facingDir", _savedField get "facingDir"],
            ["depthHalfWidth", _depthHalfWidth],
            ["frontageHalfWidth", _frontageHalfWidth],
            ["packetSummaries", _savedField get "packetSummaries"],
            ["markerName", _markerName],
            ["mineObjects", _mineObjects]
        ];

        _stagedFields set [_fieldId, _field];
        _stagedObjectiveIndex set [_objectiveId, _fieldId];
    } forEach _validatedFields;
} catch {
    _buildError = _exception;
};

if (_buildError != "") then {
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _createdMines;
    {
        deleteMarker _x;
    } forEach _createdMarkers;
    throw _buildError;
};

FLO_Minefields = _stagedFields;
FLO_MinefieldObjectiveIndex = _stagedObjectiveIndex;
FLO_MinefieldObjectiveCooldowns = _validatedCooldowns;

count _validatedFields
