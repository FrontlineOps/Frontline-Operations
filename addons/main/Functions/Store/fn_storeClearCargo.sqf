params ["_container", ["_global", false, [false]]];

if (isNull _container) exitWith { false };

if (_global) then {
    clearItemCargoGlobal _container;
    clearWeaponCargoGlobal _container;
    clearMagazineCargoGlobal _container;
    clearBackpackCargoGlobal _container;
} else {
    clearItemCargo _container;
    clearWeaponCargo _container;
    clearMagazineCargo _container;
    clearBackpackCargo _container;
};

true
