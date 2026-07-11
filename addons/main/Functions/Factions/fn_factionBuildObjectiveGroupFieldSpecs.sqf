/*
 * Function: FLO_fnc_factionBuildObjectiveGroupFieldSpecs
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds objective group edit-control specs from a starting IDC.
 *
 * Arguments:
 * 0: Starting IDC <NUMBER>
 *
 * Returns:
 * Field specs <ARRAY>
 */
params ["_startIdc"];

private _subtypes = ["capital", "city", "village", "local", "marine", "cluster"];
private _groupTypes = ["infantry", "motorized", "mechanized", "armor", "air", "artillery", "mobile_aa", "static_aa"];
private _specs = [];

{
    private _subtype = _x;
    private _subtypeOffset = _forEachIndex * count _groupTypes;

    {
        _specs pushBack [_startIdc + _subtypeOffset + _forEachIndex, "objective", _subtype, _x];
    } forEach _groupTypes;
} forEach _subtypes;

_specs
