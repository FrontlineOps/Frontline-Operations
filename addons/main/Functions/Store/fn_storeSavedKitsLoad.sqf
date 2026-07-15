if (!hasInterface) exitWith { [] };

private _hasKits = !(isNil { profileNamespace getVariable "FLO_StoreSavedKits" });

if (!_hasKits) exitWith {
    [[]] call FLO_fnc_storeSavedKitsPersist;
    []
};

private _stored = profileNamespace getVariable "FLO_StoreSavedKits";
if !(_stored isEqualType []) then {
    throw "Store saved-kit payload is not an array";
};

private _kits = [];
private _ids = createHashMap;
for "_i" from 0 to ((count _stored) - 1) do {
    private _record = [_stored select _i, _i] call FLO_fnc_storeSavedKitValidateRecord;
    private _id = _record get "id";
    if (_id in _ids) then {
        throw format ["Store saved kits contain duplicate id %1", _id];
    };
    _ids set [_id, true];
    _kits pushBack _record;
};

_kits
