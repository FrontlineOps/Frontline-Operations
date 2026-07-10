/*
 * Function: FLO_fnc_civilianRecordIntelInteraction
 */

params [
    ["_civilian", objNull, [objNull]],
    ["_groupId", "", [""]],
    ["_at", diag_tickTime, [0]]
];

if (_groupId != "") then {
    private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroupSnapshot;
    if !(isNil "_groupData") then {
        [
            _groupId,
            createHashMapFromArray [["civilianLastIntelAt", _at]]
        ] call FLO_fnc_virtualizationPatchGroup;
    };
};

if (!isNull _civilian) then {
    _civilian setVariable ["FLO_CivilianLastIntelAt", _at, true];
};

true
