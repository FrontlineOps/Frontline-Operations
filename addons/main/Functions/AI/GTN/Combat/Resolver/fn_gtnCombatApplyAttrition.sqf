/*
 * Function: FLO_fnc_gtnCombatApplyAttrition
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies virtual combat losses to the provided groups and removes depleted
 *   groups from virtualization state.
 *
 * Arguments:
 *   0: Virtual groups map <HASHMAP>
 *   1: Group references <ARRAY>
 *   2: Loss percentage <NUMBER>
 *
 * Return Value:
 *   None
 */

params ["_groups", "_groupRefs", "_lossPct"];

{
    _x params ["_groupId", "_gData"];

    private _count = _gData get "unitCount";
    if (_count <= 0) then {
        FLO_GTN_VirtualCombatResumeStates deleteAt _groupId;
        [_groupId] call FLO_fnc_virtualizationRemoveGroup;
        continue;
    };

    private _loss = ceil (_count * _lossPct * (0.85 + random 0.3));
    if (_loss < 1) then { _loss = 1 };

    private _newCount = _count - _loss;
    if (_newCount <= 0) then {
        FLO_GTN_VirtualCombatResumeStates deleteAt _groupId;
        [_groupId] call FLO_fnc_virtualizationRemoveGroup;
    } else {
        [
            _groupId,
            createHashMapFromArray [["unitCount", _newCount]]
        ] call FLO_fnc_virtualizationPatchGroup;
    };
} forEach _groupRefs;
