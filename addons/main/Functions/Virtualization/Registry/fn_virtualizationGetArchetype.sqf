/*
 * Function: FLO_fnc_virtualizationGetArchetype
 * Description:
 *   Requires the descriptor for a supported virtual-group type.
 */

params [["_groupType", "", [""]]];

private _catalog = (call FLO_fnc_virtualizationRequireRegistry) get "archetypes";
private _archetype = _catalog get _groupType;
if (isNil "_archetype") then {
    throw format ["Unsupported virtual-group archetype %1", _groupType];
};

_archetype
