/*
 * Function: FLO_fnc_logisticsNetworkGetComposition
 * Author: Frontline Operations Development Group
 * Description:
 *   Counts current managed-side virtual groups by group type.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - Group composition keyed by group type
 */

params ["_net"];

private _managedSide = _net get "_managedSide";
private _allGroups = call FLO_fnc_virtualizationGetGroupMap;
private _composition = createHashMap;

{
    private _gData = _y;
    if ((_gData get "side") isNotEqualTo _managedSide) then { continue };
    if ((_gData get "organicPackageRole") == "dismount") then { continue };
    if (_gData get "transportRole") then { continue };

    private _groupType = _gData get "groupType";
    _composition set [_groupType, (_composition getOrDefault [_groupType, 0]) + 1];
} forEach _allGroups;

_composition
