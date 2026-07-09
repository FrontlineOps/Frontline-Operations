/*
 * Function: FLO_fnc_gtnSerializeIntelSignatureRecords
 * Author: Frontline Operations Development Group
 * Description:
 *   Serializes and sorts marker records for deterministic intel publish
 *   signatures.
 *
 * Arguments:
 * 0: Records <ARRAY>
 *
 * Returns:
 * Serialized records <STRING>
 */
params ["_records"];

private _serialized = _records apply {
    (_x apply { [_x] call FLO_fnc_gtnNormalizeIntelSignatureValue }) joinString "|"
};
_serialized sort true;

_serialized joinString ";"
