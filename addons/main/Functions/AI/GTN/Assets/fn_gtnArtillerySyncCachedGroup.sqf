/*
 * Function: FLO_fnc_gtnArtillerySyncCachedGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Maintains the artillery-group cache used by the GTN artillery manager so
 *   observed-fire support and fire-mission selection do not rescan every
 *   virtual group on each request.
 *
 * Arguments:
 * 0: Artillery Manager <HASHMAP>
 * 1: Group ID <STRING>
 * 2: Group Data <HASHMAP> (optional when removing)
 * 3: Present <BOOLEAN> - true to add/update, false to remove
 *
 * Return Value:
 * Boolean - True when the group is currently cached as artillery
 */

params ["_manager", "_groupId", ["_groupData", nil], ["_present", true, [true]]];

private _cache = _manager get "artilleryGroupsBySide";
{
    (_cache get _x) deleteAt _groupId;
} forEach ["ALL", "EAST", "WEST"];

if (!_present) exitWith { false };
if (isNil "_groupData") exitWith { false };
if ((_groupData get "groupType") != "artillery") exitWith { false };

(_cache get "ALL") set [_groupId, true];

private _side = _groupData get "side";
if (_side isEqualTo east) then {
    (_cache get "EAST") set [_groupId, true];
};
if (_side isEqualTo west) then {
    (_cache get "WEST") set [_groupId, true];
};

true
