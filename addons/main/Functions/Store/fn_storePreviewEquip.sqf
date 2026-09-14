/* Preview one item against the current player loadout, without accumulating selections. */
params ["_man", "_baseline", "_class", "_category"];
_man setUnitLoadout _baseline;
switch (_category) do {
    case "uniforms": {removeUniform _man; _man forceAddUniform _class};
    case "vests": {removeVest _man; _man addVest _class};
    case "backpacks": {removeBackpack _man; _man addBackpack _class};
    case "headgear": {removeHeadgear _man; _man addHeadgear _class};
    case "facewear": {removeGoggles _man; _man addGoggles _class};
    case "primary";
    case "handgun";
    case "secondary": {
        private _old = switch (_category) do {
            case "primary": {primaryWeapon _man};
            case "handgun": {handgunWeapon _man};
            case "secondary": {secondaryWeapon _man};
        };
        _man removeWeapon _old;
        _man addWeapon _class;
        _man selectWeapon _class;
    };
    case "attachments": {
        if (_class in (compatibleItems (primaryWeapon _man))) then {_man addPrimaryWeaponItem _class};
    };
    case "misc": {
        if (((_class call BIS_fnc_itemType) select 1) in ["NVGoggles", "GPS", "Map", "Compass", "Watch", "Radio", "Terminal"]) then {_man linkItem _class};
    };
};
private _pose = switch (_category) do {
    case "handgun": {"AmovPercMstpSrasWpstDnon"};
    case "secondary": {"AmovPercMstpSrasWlnrDnon"};
    case "primary";
    case "attachments": {"AmovPercMstpSlowWrflDnon"};
    default {"AmovPercMstpSnonWnonDnon"};
};
_man switchMove _pose;
