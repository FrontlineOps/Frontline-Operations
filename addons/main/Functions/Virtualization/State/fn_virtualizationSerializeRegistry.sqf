/*
 * Function: FLO_fnc_virtualizationSerializeRegistry
 * Description:
 *   Builds a complete validated virtual-force snapshot. Any invalid record
 *   throws so the mission save transaction cannot publish partial force data.
 */

call FLO_fnc_virtualizationValidateRegistry;

private _serialized = createHashMap;
{
    _serialized set [_x, [_y] call FLO_fnc_virtualizationSerializeGroup];
} forEach (call FLO_fnc_virtualizationGetGroupMap);

_serialized
