/* Awards persistent experience to every surviving group in one resolved remote engagement. */
params [
    ["_outcome", createHashMap, [createHashMap]],
    ["_eastGroupIds", [], [[]]],
    ["_westGroupIds", [], [[]]]
];

private _winner = _outcome get "winner";
private _decisive = _outcome get "decisive";
private _updatedCount = 0;
private _decisiveWinnerCount = 0;
{
    _x params ["_side", "_groupIds"];
    private _gain = [1, 5] select (_decisive && {_winner isEqualTo _side});
    {
        private _groupData = [_x] call FLO_fnc_virtualizationFindGroupSnapshot;
        if (isNil "_groupData") then { continue };
        if ((_groupData get "unitCount") <= 0) then { continue };
        private _experience = ((_groupData get "combatExperience") + _gain) min 100;
        [_x, createHashMapFromArray [["combatExperience", _experience]]] call FLO_fnc_virtualizationPatchGroup;
        if (_groupData get "isActive") then {
            private _updatedGroup = [_x] call FLO_fnc_virtualizationFindGroupSnapshot;
            [_x, _updatedGroup get "realGroup"] call FLO_fnc_gtnCombatApplyGroupSkills;
        };
        _updatedCount = _updatedCount + 1;
        if (_gain == 5) then { _decisiveWinnerCount = _decisiveWinnerCount + 1; };
    } forEach _groupIds;
} forEach [[east, _eastGroupIds], [west, _westGroupIds]];

if (_updatedCount > 0) then {
    ["GTN_COMBAT", 4, format [
        "Group experience updated survivors=%1 decisiveWinners=%2",
        _updatedCount,
        _decisiveWinnerCount
    ]] call FLO_fnc_log;
};
_updatedCount
