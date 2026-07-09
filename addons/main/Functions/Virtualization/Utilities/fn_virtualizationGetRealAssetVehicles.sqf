/*
 * Function: FLO_fnc_virtualizationGetRealAssetVehicles
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the surviving real vehicle assets that still represent the virtual
 *   group's combat strength. Static AA excludes radar vehicles so only launcher
 *   assets count toward persistence.
 *
 * Arguments:
 * 0: Group Data <HASHMAP>
 * 1: Real Group <GROUP>
 *
 * Return Value:
 * Array - Surviving asset vehicles
 */

params ["_groupData", "_realGroup"];

private _groupType = _groupData get "groupType";
if !([_groupType] call FLO_fnc_virtualizationUsesAssetStrength) exitWith { [] };

private _assetVehicles = (_groupData get "realVehicles") select { !isNull _x && {alive _x} };
if (_assetVehicles isEqualTo [] && {!isNull _realGroup}) then {
    _assetVehicles = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { alive _x };
};

if (_groupType isEqualTo "static_aa") then {
    private _side = _groupData get "side";
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    private _catalog = FLO_FactionCatalog get _sideKey;
    private _radarTypes = _catalog get "radar";

    _assetVehicles = _assetVehicles select {
        private _vehType = typeOf _x;
        !(_vehType in _radarTypes)
    };
};

_assetVehicles
