/*
 * Function: FLO_fnc_storeDropGearAddCount
 * Author: Frontline Operations Development Group
 * Description:
 *   Increments a gear-drop bucket and returns the updated total drop count.
 *
 * Arguments:
 * 0: Bucket <HASHMAP>
 * 1: Class name <STRING>
 * 2: Current drop count <NUMBER>
 *
 * Returns:
 * Updated drop count <NUMBER>
 */
params ["_bucket", "_className", "_dropCount"];

_bucket set [_className, (_bucket getOrDefault [_className, 0]) + 1];
_dropCount + 1
