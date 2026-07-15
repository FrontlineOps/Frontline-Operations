/*
 * Function: FLO_fnc_minefieldValidateSavedField
 * Author: Frontline Operations Development Group
 * Description:
 *   Validates one exact current-version minefield save record.
 *
 * Arguments:
 * 0: Saved field <HASHMAP>
 * 1: Record index <SCALAR>
 *
 * Return Value:
 * BOOL
 */

params ["_savedField", "_recordIndex"];

if !(_savedField isEqualType createHashMap) then {
    throw format ["Minefield record %1 has invalid type %2", _recordIndex, typeName _savedField];
};
if !(_recordIndex isEqualType 0) then {
    throw format ["Minefield record index has invalid type %1", typeName _recordIndex];
};

private _requiredFieldKeys = [
    "id",
    "objectiveId",
    "sideKey",
    "threatSignature",
    "centerPos",
    "anchorPos",
    "facingDir",
    "frontageHalfWidth",
    "packetSummaries",
    "mineSpecs"
];
private _missingFields = _requiredFieldKeys select {!(_x in _savedField)};
private _recordKeys = keys _savedField;
private _unsupportedFields = _recordKeys select {!(_x in _requiredFieldKeys)};
if (_missingFields isNotEqualTo []) then {
    throw format ["Minefield record %1 is missing fields %2", _recordIndex, _missingFields];
};
if (_unsupportedFields isNotEqualTo []) then {
    throw format ["Minefield record %1 has unsupported fields %2", _recordIndex, _unsupportedFields];
};

private _fieldId = _savedField get "id";
private _objectiveId = _savedField get "objectiveId";
private _sideKey = _savedField get "sideKey";
private _threatSignature = _savedField get "threatSignature";
private _facingDir = _savedField get "facingDir";
private _frontageHalfWidth = _savedField get "frontageHalfWidth";
private _packetSummaries = _savedField get "packetSummaries";
private _mineSpecs = _savedField get "mineSpecs";

if !(_fieldId isEqualType "") then {
    throw format ["Minefield record %1 id has invalid type %2", _recordIndex, typeName _fieldId];
};
if (_fieldId == "") then {
    throw format ["Minefield record %1 has an empty id", _recordIndex];
};
if !(_objectiveId isEqualType "") then {
    throw format ["Minefield %1 objectiveId has invalid type %2", _fieldId, typeName _objectiveId];
};
if (_objectiveId == "") then {
    throw format ["Minefield %1 has an empty objectiveId", _fieldId];
};
if !(_sideKey isEqualType "") then {
    throw format ["Minefield %1 sideKey has invalid type %2", _fieldId, typeName _sideKey];
};
if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["Minefield %1 has unsupported side %2", _fieldId, _sideKey];
};
if !(_threatSignature isEqualType "") then {
    throw format ["Minefield %1 threatSignature has invalid type %2", _fieldId, typeName _threatSignature];
};
private _expectedSignaturePrefix = format ["%1|%2|", _sideKey, _objectiveId];
if ((_threatSignature find _expectedSignaturePrefix) != 0) then {
    throw format ["Minefield %1 has a foreign threat signature %2", _fieldId, _threatSignature];
};
if !(_facingDir isEqualType 0) then {
    throw format ["Minefield %1 facingDir has invalid type %2", _fieldId, typeName _facingDir];
};
if !(_frontageHalfWidth isEqualType 0) then {
    throw format ["Minefield %1 frontageHalfWidth has invalid type %2", _fieldId, typeName _frontageHalfWidth];
};
if (_frontageHalfWidth <= 0) then {
    throw format ["Minefield %1 has invalid frontageHalfWidth %2", _fieldId, _frontageHalfWidth];
};
if !(_packetSummaries isEqualType []) then {
    throw format ["Minefield %1 packetSummaries have invalid type %2", _fieldId, typeName _packetSummaries];
};
if (_packetSummaries isEqualTo []) then {
    throw format ["Minefield %1 has no packet summaries", _fieldId];
};
if !(_mineSpecs isEqualType []) then {
    throw format ["Minefield %1 mineSpecs have invalid type %2", _fieldId, typeName _mineSpecs];
};
if (_mineSpecs isEqualTo []) then {
    throw format ["Minefield %1 has no mine specifications", _fieldId];
};

{
    private _positionField = _x;
    private _position = _savedField get _positionField;
    if !(_position isEqualType []) then {
        throw format ["Minefield %1 %2 has invalid type %3", _fieldId, _positionField, typeName _position];
    };
    if ((count _position) != 3) then {
        throw format ["Minefield %1 %2 is malformed: %3", _fieldId, _positionField, _position];
    };
    {
        private _coordinate = _x;
        if !(_coordinate isEqualType 0) then {
            throw format ["Minefield %1 %2 coordinate %3 has invalid type %4", _fieldId, _positionField, _forEachIndex, typeName _coordinate];
        };
    } forEach _position;
} forEach ["centerPos", "anchorPos"];

if !(_objectiveId in FLO_Objectives) then {
    throw format ["Minefield %1 references missing objective %2", _fieldId, _objectiveId];
};
private _side = [east, west] select (_sideKey isEqualTo "WEST");
private _objective = FLO_Objectives get _objectiveId;
if ((_objective get "owner") != _side) then {
    throw format [
        "Minefield %1 side %2 does not own objective %3",
        _fieldId,
        _sideKey,
        _objectiveId
    ];
};

private _requiredPacketKeys = [
    "id",
    "role",
    "anchorPos",
    "dir",
    "halfWidth",
    "layers",
    "slotSpacing",
    "shoulderWidth",
    "allowAT"
];
private _packetIds = createHashMap;
{
    private _packetIndex = _forEachIndex;
    private _packet = _x;
    if !(_packet isEqualType createHashMap) then {
        throw format ["Minefield %1 packet %2 has invalid type %3", _fieldId, _packetIndex, typeName _packet];
    };

    private _missingPacketFields = _requiredPacketKeys select {!(_x in _packet)};
    private _packetKeys = keys _packet;
    private _unsupportedPacketFields = _packetKeys select {!(_x in _requiredPacketKeys)};
    if (_missingPacketFields isNotEqualTo []) then {
        throw format ["Minefield %1 packet %2 is missing fields %3", _fieldId, _packetIndex, _missingPacketFields];
    };
    if (_unsupportedPacketFields isNotEqualTo []) then {
        throw format ["Minefield %1 packet %2 has unsupported fields %3", _fieldId, _packetIndex, _unsupportedPacketFields];
    };

    private _packetId = _packet get "id";
    private _role = _packet get "role";
    private _anchorPos = _packet get "anchorPos";
    private _dir = _packet get "dir";
    private _halfWidth = _packet get "halfWidth";
    private _layers = _packet get "layers";
    private _slotSpacing = _packet get "slotSpacing";
    private _shoulderWidth = _packet get "shoulderWidth";
    private _allowAT = _packet get "allowAT";

    if !(_packetId isEqualType "") then {
        throw format ["Minefield %1 packet %2 id has invalid type %3", _fieldId, _packetIndex, typeName _packetId];
    };
    if (_packetId == "") then {
        throw format ["Minefield %1 packet %2 has an empty id", _fieldId, _packetIndex];
    };
    if (_packetId in _packetIds) then {
        throw format ["Minefield %1 has duplicate packet id %2", _fieldId, _packetId];
    };
    if !(_role isEqualType "") then {
        throw format ["Minefield %1 packet %2 role has invalid type %3", _fieldId, _packetId, typeName _role];
    };
    if !(_role in ["frontage", "road", "cover", "bypass"]) then {
        throw format ["Minefield %1 packet %2 has unsupported role %3", _fieldId, _packetId, _role];
    };
    if !(_anchorPos isEqualType []) then {
        throw format ["Minefield %1 packet %2 anchorPos has invalid type %3", _fieldId, _packetId, typeName _anchorPos];
    };
    if ((count _anchorPos) != 3) then {
        throw format ["Minefield %1 packet %2 anchorPos is malformed: %3", _fieldId, _packetId, _anchorPos];
    };
    {
        if !(_x isEqualType 0) then {
            throw format ["Minefield %1 packet %2 anchor coordinate %3 has invalid type %4", _fieldId, _packetId, _forEachIndex, typeName _x];
        };
    } forEach _anchorPos;
    {
        _x params ["_name", "_value", "_minimum"];
        if !(_value isEqualType 0) then {
            throw format ["Minefield %1 packet %2 %3 has invalid type %4", _fieldId, _packetId, _name, typeName _value];
        };
        if (_value < _minimum) then {
            throw format ["Minefield %1 packet %2 has invalid %3 value %4", _fieldId, _packetId, _name, _value];
        };
    } forEach [
        ["dir", _dir, -1e12],
        ["halfWidth", _halfWidth, 0.0001],
        ["layers", _layers, 1],
        ["slotSpacing", _slotSpacing, 0.0001],
        ["shoulderWidth", _shoulderWidth, 0]
    ];
    if ((floor _layers) != _layers) then {
        throw format ["Minefield %1 packet %2 layers must be an integer: %3", _fieldId, _packetId, _layers];
    };
    if !(_allowAT isEqualType false) then {
        throw format ["Minefield %1 packet %2 allowAT has invalid type %3", _fieldId, _packetId, typeName _allowAT];
    };

    _packetIds set [_packetId, true];
} forEach _packetSummaries;

private _requiredMineSpecKeys = ["type", "posASL"];
{
    private _mineIndex = _forEachIndex;
    private _mineSpec = _x;
    if !(_mineSpec isEqualType createHashMap) then {
        throw format ["Minefield %1 mine %2 has invalid type %3", _fieldId, _mineIndex, typeName _mineSpec];
    };

    private _missingMineFields = _requiredMineSpecKeys select {!(_x in _mineSpec)};
    private _mineKeys = keys _mineSpec;
    private _unsupportedMineFields = _mineKeys select {!(_x in _requiredMineSpecKeys)};
    if (_missingMineFields isNotEqualTo []) then {
        throw format ["Minefield %1 mine %2 is missing fields %3", _fieldId, _mineIndex, _missingMineFields];
    };
    if (_unsupportedMineFields isNotEqualTo []) then {
        throw format ["Minefield %1 mine %2 has unsupported fields %3", _fieldId, _mineIndex, _unsupportedMineFields];
    };

    private _mineType = _mineSpec get "type";
    private _minePos = _mineSpec get "posASL";
    if !(_mineType isEqualType "") then {
        throw format ["Minefield %1 mine %2 type has invalid type %3", _fieldId, _mineIndex, typeName _mineType];
    };
    if (_mineType == "" || {!isClass (configFile >> "CfgAmmo" >> _mineType)}) then {
        throw format ["Minefield %1 mine %2 has invalid ammo class %3", _fieldId, _mineIndex, _mineType];
    };
    if !(_minePos isEqualType []) then {
        throw format ["Minefield %1 mine %2 posASL has invalid type %3", _fieldId, _mineIndex, typeName _minePos];
    };
    if ((count _minePos) != 3) then {
        throw format ["Minefield %1 mine %2 posASL is malformed: %3", _fieldId, _mineIndex, _minePos];
    };
    {
        if !(_x isEqualType 0) then {
            throw format ["Minefield %1 mine %2 coordinate %3 has invalid type %4", _fieldId, _mineIndex, _forEachIndex, typeName _x];
        };
    } forEach _minePos;
} forEach _mineSpecs;

true
