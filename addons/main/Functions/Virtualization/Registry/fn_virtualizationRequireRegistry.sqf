/*
 * Function: FLO_fnc_virtualizationRequireRegistry
 */

if (isNil "FLO_VirtualForceRegistry") then {
    throw "FLO virtual-force registry is not initialized";
};
if !(FLO_VirtualForceRegistry isEqualType createHashMap) then {
    throw format [
        "FLO virtual-force registry has invalid type %1",
        typeName FLO_VirtualForceRegistry
    ];
};

FLO_VirtualForceRegistry
