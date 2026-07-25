/* Hands an aircraft that activated during abstract resolution back to physical AA ownership. */
params [
    ["_airGroupId", "", [""]],
    ["_airData", nil],
    ["_groups", createHashMap, [createHashMap]],
    ["_contactIndex", createHashMap, [createHashMap]],
    ["_aaGroupId", "", [""]]
];

if (isNil "_airData") then { throw "Active air-defense handoff requires aircraft state"; };
if !(_airData get "isActive") exitWith { createHashMap };

private _realGroup = _airData get "realGroup";
if (isNull _realGroup) then {
    private _message = format ["Active air-defense handoff found null realGroup for %1", _airGroupId];
    ["GTN Air Defense", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _vehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
if (_vehicles isNotEqualTo []) then {
    [
        _vehicles select 0,
        _airData get "side",
        _groups,
        _contactIndex,
        false
    ] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft;
};

private _state = call FLO_fnc_gtnAirDefenseGetState;
(_state get "virtualExposureByAircraft") deleteAt _airGroupId;

["GTN Air Defense", 3, format [
    "Abstract engagement yielded to active aircraft %1 against AA %2",
    _airGroupId,
    _aaGroupId
]] call FLO_fnc_log;

createHashMapFromArray [["status", "PHYSICAL"], ["aaGroupId", _aaGroupId], ["losses", 0]]
