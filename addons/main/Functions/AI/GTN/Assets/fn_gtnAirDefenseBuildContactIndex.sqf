/* Builds one side-filtered canonical air/AA index for an air-defense pass. */
params [["_groups", createHashMap, [createHashMap]]];

private _airGroupIds = [];
private _aaGroupIdsBySide = createHashMapFromArray [
    ["WEST", []],
    ["EAST", []]
];
private _aaCount = 0;

{
    private _groupId = _x;
    private _groupData = _y;
    private _groupType = _groupData get "groupType";
    if (_groupType in ["helicopter", "air", "jet"] && {(_groupData get "unitCount") > 0}) then {
        _airGroupIds pushBack _groupId;
    };
    if (
        _groupType in ["static_aa", "mobile_aa"]
        && {(_groupData get "unitCount") > 0}
        && {(_groupData get "replacementState") == ""}
    ) then {
        private _sideKey = [_groupData get "side"] call FLO_fnc_sideKey;
        if !(_sideKey in _aaGroupIdsBySide) then {
            private _message = format ["AA group %1 has unsupported side %2", _groupId, _sideKey];
            ["GTN Air Defense", 1, _message] call FLO_fnc_log;
            throw _message;
        };
        (_aaGroupIdsBySide get _sideKey) pushBack _groupId;
        _aaCount = _aaCount + 1;
    };
} forEach _groups;

createHashMapFromArray [
    ["airGroupIds", _airGroupIds],
    ["aaGroupIdsBySide", _aaGroupIdsBySide],
    ["aaCount", _aaCount]
]
