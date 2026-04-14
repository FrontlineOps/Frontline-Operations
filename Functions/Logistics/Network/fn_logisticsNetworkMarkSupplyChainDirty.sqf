/*
 * Function: FLO_fnc_logisticsNetworkMarkSupplyChainDirty
 * Author: Frontline Operations Development Group
 * Description:
 *   Marks cached supply-chain state dirty so the next consumer refreshes the
 *   graph instead of paying for unconditional rebuilds every logistics tick.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Dirty objective-side index too <BOOL> - Default true
 *
 * Return Value:
 *   BOOL - True when the network was marked dirty
 */

params [
    ["_net", nil],
    ["_dirtyObjectiveIndex", true, [true]]
];

if (isNil "_net") exitWith { false };

_net set ["_supplyChainDirty", true];
if (_dirtyObjectiveIndex) then {
    _net set ["_objectiveSideIndexDirty", true];
};

_net set ["_targetPicture", createHashMap];
_net set ["_dispatchRoleCache", createHashMap];
_net set ["_dispatchBranchCache", createHashMap];
_net set ["_dispatchEnemyDistanceCache", createHashMap];
_net set ["_dispatchSourceableCache", createHashMap];
_net set ["_dispatchDeliveryObjectiveCache", createHashMap];

true
