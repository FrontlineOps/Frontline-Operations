/*
 * Function: FLO_fnc_factionBuildTuningFieldSpecsFromIdcs
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds force composition edit-control specs from IDC ranges.
 *
 * Arguments:
 * 0: Ground reserve IDC <NUMBER>
 * 1: Air reserve IDC <NUMBER>
 * 2: Cap range start IDC <NUMBER>
 * 3: Count range start IDC <NUMBER>
 *
 * Returns:
 * Field specs <ARRAY>
 */
params ["_reserveGroundIdc", "_reserveAirIdc", "_capStartIdc", "_countStartIdc"];

private _groupTypes = [
    ["infantry", 0],
    ["motorized", 1],
    ["mechanized", 2],
    ["armor", 3],
    ["helicopter", 4],
    ["jet", 5],
    ["air", 6],
    ["artillery", 7],
    ["mobile_aa", 8],
    ["static_aa", 9]
];

private _specs = [
    [_reserveGroundIdc, "scalar", "transportReserveGroundCount"],
    [_reserveAirIdc, "scalar", "transportReserveAirCount"]
];

{
    _x params ["_key", "_offset"];
    _specs pushBack [_capStartIdc + _offset, "cap", _key];
} forEach _groupTypes;

{
    _x params ["_key", "_offset"];
    _specs pushBack [_countStartIdc + _offset, "count", _key];
} forEach _groupTypes;

_specs
