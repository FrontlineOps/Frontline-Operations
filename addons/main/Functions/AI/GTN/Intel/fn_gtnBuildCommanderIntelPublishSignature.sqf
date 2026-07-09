/*
 * Function: FLO_fnc_gtnBuildCommanderIntelPublishSignature
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a deterministic signature string for the commander COP publish
 *   payload so unchanged pictures can be skipped.
 *
 * Arguments:
 *   0: Side key <STRING>
 *   1: Enemy group marker records <ARRAY>
 *   2: Enemy concentration marker records <ARRAY>
 *   3: Friendly group marker records <ARRAY>
 *   4: Support marker records <ARRAY>
 *
 * Return Value:
 *   Signature <STRING>
 */

params [
    ["_sideKey", "", [""]],
    ["_enemyGroupMarkers", [], [[]]],
    ["_enemyConcentrationMarkers", [], [[]]],
    ["_friendlyGroupMarkers", [], [[]]],
    ["_supportMarkers", [], [[]]]
];

[
    _sideKey,
    [_enemyGroupMarkers] call FLO_fnc_gtnSerializeIntelSignatureRecords,
    [_enemyConcentrationMarkers] call FLO_fnc_gtnSerializeIntelSignatureRecords,
    [_friendlyGroupMarkers] call FLO_fnc_gtnSerializeIntelSignatureRecords,
    [_supportMarkers] call FLO_fnc_gtnSerializeIntelSignatureRecords
] joinString "||"
