params ["_unit", "_classNames"];

if (!hasInterface) exitWith { 0 };
if (isNull _unit) exitWith { 0 };
if ((typeName _classNames) isNotEqualTo "ARRAY") exitWith { 0 };
if (_classNames isEqualTo []) exitWith { 0 };

private _weapons = createHashMap;
private _magazines = createHashMap;
private _items = createHashMap;
private _backpacks = createHashMap;
private _dropCount = 0;

{
    if ((typeName _x) isNotEqualTo "STRING") then { continue };
    if (_x isEqualTo "") then { continue };

    if (isClass (configFile >> "CfgVehicles" >> _x) && {(getNumber (configFile >> "CfgVehicles" >> _x >> "isBackpack")) isEqualTo 1}) then {
        _dropCount = [_backpacks, _x, _dropCount] call FLO_fnc_storeDropGearAddCount;
        continue;
    };

    if (isClass (configFile >> "CfgMagazines" >> _x)) then {
        _dropCount = [_magazines, _x, _dropCount] call FLO_fnc_storeDropGearAddCount;
        continue;
    };

    if (isClass (configFile >> "CfgWeapons" >> _x)) then {
        private _itemType = _x call BIS_fnc_itemType;
        private _group = _itemType param [0, ""];

        if (_group isEqualTo "Weapon") then {
            _dropCount = [_weapons, _x, _dropCount] call FLO_fnc_storeDropGearAddCount;
        } else {
            _dropCount = [_items, _x, _dropCount] call FLO_fnc_storeDropGearAddCount;
        };

        continue;
    };

    if (isClass (configFile >> "CfgGlasses" >> _x)) then {
        _dropCount = [_items, _x, _dropCount] call FLO_fnc_storeDropGearAddCount;
    };
} forEach _classNames;

if (_dropCount <= 0) exitWith { 0 };

private _dropPos = _unit modelToWorld [0, 1.4, 0];
_dropPos set [2, (getPosATL _unit) # 2];

private _holder = createVehicle ["GroundWeaponHolder", _dropPos, [], 0, "CAN_COLLIDE"];
_holder setDir (getDir _unit);

{
    _holder addWeaponCargoGlobal [_x, _weapons get _x];
} forEach (keys _weapons);

{
    _holder addMagazineCargoGlobal [_x, _magazines get _x];
} forEach (keys _magazines);

{
    _holder addItemCargoGlobal [_x, _items get _x];
} forEach (keys _items);

{
    _holder addBackpackCargoGlobal [_x, _backpacks get _x];
} forEach (keys _backpacks);

_dropCount
