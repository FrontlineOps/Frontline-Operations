/*
 * Function: FLO_fnc_virtualizationGetSpatialState
 */

private _registry = call FLO_fnc_virtualizationRequireRegistry;
private _spatial = _registry get "spatial";
if ((keys _spatial) isEqualTo []) then {
    throw "Virtualization spatial state is not initialized";
};

_spatial
