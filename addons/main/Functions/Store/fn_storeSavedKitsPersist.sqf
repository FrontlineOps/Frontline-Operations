params ["_kits"];

if (!hasInterface) then {
    throw "Store saved kits can only be persisted by an interface client";
};
if !(_kits isEqualType []) then {
    throw "Store saved-kit persistence requires an array";
};

profileNamespace setVariable ["FLO_StoreSavedKitsSchemaVersion", FLO_StoreSavedKitsCurrentSchemaVersion];
profileNamespace setVariable ["FLO_StoreSavedKits", _kits];
saveProfileNamespace;
true
