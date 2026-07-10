/*
 * Function: FLO_fnc_virtualizationTouchRegistry
 */

private _registry = call FLO_fnc_virtualizationRequireRegistry;
_registry set ["revision", (_registry get "revision") + 1];
_registry get "revision"
