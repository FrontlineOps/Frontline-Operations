params ["_className"];

private _weaponCfg = configFile >> "CfgWeapons" >> _className;
if !(isClass _weaponCfg) exitWith { [] };

private _linkedCfg = _weaponCfg >> "LinkedItems";
if !(isClass _linkedCfg) exitWith { [] };

private _slotLabels = createHashMapFromArray [
    ["MuzzleSlot", "Muzzle"],
    ["CowsSlot", "Optic"],
    ["PointerSlot", "Pointer"],
    ["UnderBarrelSlot", "Underbarrel"]
];
private _attachments = [];

{
    private _attachmentClass = getText (_x >> "item");
    if (_attachmentClass isEqualTo "") then { continue };
    if !(isClass (configFile >> "CfgWeapons" >> _attachmentClass)) then { continue };

    private _slot = getText (_x >> "slot");
    private _attachmentCfg = configFile >> "CfgWeapons" >> _attachmentClass;
    private _name = getText (_attachmentCfg >> "displayName");
    private _slotName = "Attachment";

    if (_name isEqualTo "") then {
        _name = _attachmentClass;
    };

    if (_slot in _slotLabels) then {
        _slotName = _slotLabels get _slot;
    };

    _attachments pushBack createHashMapFromArray [
        ["className", _attachmentClass],
        ["name", _name],
        ["slot", _slot],
        ["slotName", _slotName],
        ["image", getText (_attachmentCfg >> "picture")]
    ];
} forEach ("true" configClasses _linkedCfg);

_attachments
