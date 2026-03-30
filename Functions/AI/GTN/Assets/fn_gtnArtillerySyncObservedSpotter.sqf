/*
 * Function: FLO_fnc_gtnArtillerySyncObservedSpotter
 * Author: Frontline Operations Development Group
 * Description:
 *   Adds or removes a virtual group from the observed-fire spotter pool used
 *   by the artillery manager.
 *
 * Arguments:
 * 0: Artillery Manager <HASHMAP>
 * 1: Group ID <STRING>
 * 2: Group Data <HASHMAP>
 *
 * Return Value:
 * Boolean - True when the group is an eligible observed-fire spotter
 *
 * Example:
 * [FLO_GTNArtilleryManager, "vgroup_1", _groupData] call FLO_fnc_gtnArtillerySyncObservedSpotter;
 */

params ["_manager", "_groupId", "_groupData"];

private _spotters = _manager get "observedSpotters";
private _side = _groupData get "side";
if !(_side in [east, west]) exitWith {
    _spotters deleteAt _groupId;
    false
};

private _groupType = _groupData get "groupType";
if !(_groupType in ["infantry", "motorized", "mechanized", "armor"]) exitWith {
    _spotters deleteAt _groupId;
    false
};

if !(_groupData get "isActive") exitWith {
    _spotters deleteAt _groupId;
    false
};

if (([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) != "") exitWith {
    _spotters deleteAt _groupId;
    false
};

if (([_groupData] call FLO_fnc_virtualizationGetMountedTransport) != "") exitWith {
    _spotters deleteAt _groupId;
    false
};

private _realGroup = _groupData get "realGroup";
if (isNil "_realGroup") exitWith {
    _spotters deleteAt _groupId;
    false
};
if (isNull _realGroup) exitWith {
    _spotters deleteAt _groupId;
    false
};

private _leader = leader _realGroup;
if (isNull _leader || {!alive _leader}) exitWith {
    _spotters deleteAt _groupId;
    false
};

_spotters set [_groupId, true];
true
