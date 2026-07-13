if (!hasInterface) exitWith { [] };

private _hasVersion = !(isNil { profileNamespace getVariable "FLO_StoreSavedKitsSchemaVersion" });
private _hasKits = !(isNil { profileNamespace getVariable "FLO_StoreSavedKits" });

if (!_hasVersion) exitWith {
    if (!_hasKits) exitWith {
        [[]] call FLO_fnc_storeSavedKitsPersist;
        []
    };

    private _legacyKits = profileNamespace getVariable "FLO_StoreSavedKits";
    if !(_legacyKits isEqualType []) then {
        throw "Legacy Store saved-kit payload is not an array";
    };

    private _migrated = [];
    private _ids = createHashMap;
    for "_i" from 0 to ((count _legacyKits) - 1) do {
        private _record = [_legacyKits select _i, _i, true] call FLO_fnc_storeSavedKitValidateRecord;
        private _id = _record get "id";
        if (_id in _ids) then {
            throw format ["Legacy Store saved kits contain duplicate id %1", _id];
        };
        _ids set [_id, true];
        _migrated pushBack _record;
    };

    [_migrated] call FLO_fnc_storeSavedKitsPersist;
    ["STORE", 3, format [
        "Saved kits migrated: schema=0->%1 records=%2",
        FLO_StoreSavedKitsCurrentSchemaVersion,
        count _migrated
    ]] call FLO_fnc_log;
    _migrated
};

private _schemaVersion = profileNamespace getVariable "FLO_StoreSavedKitsSchemaVersion";
if !(_schemaVersion isEqualType 0) then {
    throw "Store saved-kit schema version is not numeric";
};
if (_schemaVersion != FLO_StoreSavedKitsCurrentSchemaVersion) then {
    throw format ["Unsupported Store saved-kit schema version: %1", _schemaVersion];
};
if (!_hasKits) then {
    throw format ["Store saved-kit schema %1 has no payload", _schemaVersion];
};

private _stored = profileNamespace getVariable "FLO_StoreSavedKits";
if !(_stored isEqualType []) then {
    throw format ["Store saved-kit schema %1 payload is not an array", _schemaVersion];
};

private _kits = [];
private _ids = createHashMap;
for "_i" from 0 to ((count _stored) - 1) do {
    private _record = [_stored select _i, _i, false] call FLO_fnc_storeSavedKitValidateRecord;
    private _id = _record get "id";
    if (_id in _ids) then {
        throw format ["Store saved kits contain duplicate id %1", _id];
    };
    _ids set [_id, true];
    _kits pushBack _record;
};

_kits
