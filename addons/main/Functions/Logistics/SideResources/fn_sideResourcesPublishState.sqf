/*
 * Function: FLO_fnc_sideResourcesPublishState
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a lightweight, network-safe snapshot of current side resources.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Snapshot <HASHMAP>
 *
 * Example:
 *   [] call FLO_fnc_sideResourcesPublishState;
 */

private _snapshot = createHashMap;

{
    private _resourceObj = FLO_SideResources get _x;
    _snapshot set [_x, [_resourceObj] call FLO_fnc_sideResourcesSerialize];
} forEach (keys FLO_SideResources);

FLO_SideResourceState = _snapshot;
publicVariable "FLO_SideResourceState";

_snapshot
