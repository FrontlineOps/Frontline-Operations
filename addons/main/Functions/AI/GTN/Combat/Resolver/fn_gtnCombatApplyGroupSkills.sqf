/* Applies one virtual group's persistent experience to its active physical AI. */
params [
    ["_groupId", "", [""]],
    ["_realGroup", grpNull, [grpNull]]
];

private _fail = {
    params ["_message"];
    ["GTN_COMBAT", 1, _message] call FLO_fnc_log;
    throw _message;
};
if (_groupId == "") then { ["Group skill application requires a virtual group ID"] call _fail; };
if (isNull _realGroup) then { [format ["Group skill application received null real group for %1", _groupId]] call _fail; };
private _groupData = [_groupId] call FLO_fnc_virtualizationFindGroupSnapshot;
if (isNil "_groupData") then {
    [format ["Group skill application cannot find virtual group %1", _groupId]] call _fail;
};
if ((_groupData get "realGroup") isNotEqualTo _realGroup) then {
    [format ["Group skill application ownership mismatch for %1", _groupId]] call _fail;
};
if !((_groupData get "side") in [east, west]) exitWith { false };
if (_groupData get "transportRole") exitWith { false };

private _experience = _groupData get "combatExperience";
private _skill = 0.37 + ((_experience / 100) * 0.61);
{
    if (!isPlayer _x && {alive _x}) then {
        _x setSkill ["aimingAccuracy", _skill];
        _x setSkill ["aimingShake", _skill];
        _x setSkill ["aimingSpeed", _skill];
        _x setSkill ["spotDistance", _skill];
        _x setSkill ["spotTime", _skill];
        _x setSkill ["courage", _skill];
        _x setSkill ["commanding", _skill];
        _x setSkill ["reloadSpeed", _skill];
        _x setSkill ["general", _skill];
    };
} forEach units _realGroup;
_realGroup setVariable ["FLO_CombatExperience", _experience, true];
_realGroup setVariable ["FLO_CombatRank", [_experience] call FLO_fnc_gtnCombatGetExperienceRank, true];
true
