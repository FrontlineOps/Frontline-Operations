/*
 * Function: FLO_fnc_virtualizationGetGroupMap
 * Description:
 *   Returns the canonical group map for read-only iteration. Mutations must go
 *   through virtualization command functions so derived state stays coherent.
 */

private _registry = call FLO_fnc_virtualizationRequireRegistry;
_registry get "groups"
