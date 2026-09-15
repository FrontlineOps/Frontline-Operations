/*
 * Function: FLO_fnc_virtualizationSerializeGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Serializes the canonical virtual-group state for persistence.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * HASHMAP - Serialized group record
 */

params ["_groupData", ["_capturedAtTick", diag_tickTime, [0]]];

if !("id" in _groupData) then { throw "[VIRTUALIZATION] Captured group missing id"; };
private _groupId = _groupData get "id";
if !(_groupId isEqualType "" && {_groupId != ""}) then {
    throw "[VIRTUALIZATION] Captured group has invalid id";
};
// Live handles were validated at capture. They may be deleted while this
// detached snapshot waits for scheduled encoding; only saved values belong here.

private _savedData = createHashMap;
{
    if !(_x in _groupData) then {
        throw format ["[VIRTUALIZATION] Captured group %1 missing persistent field %2", _groupId, _x];
    };
    _savedData set [
        _x,
        [_groupData get _x] call FLO_fnc_virtualizationCloneValue
    ];
} forEach (call FLO_fnc_virtualizationGetPersistentFields);

// Anchor process-relative deadlines and elapsed ages to this coherent capture.
_savedData set ["timerSampleTick", _capturedAtTick];
_savedData set ["timerElapsedOffsets", createHashMapFromArray [
    ["civilianLastIntelAt", _groupData get "civilianIntelElapsedOffset"]
]];

[_savedData, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
_savedData

