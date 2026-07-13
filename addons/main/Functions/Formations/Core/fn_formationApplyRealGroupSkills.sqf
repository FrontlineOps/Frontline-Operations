/* Applies restrained formation quality to one active physical AI group. */
params [
    ["_groupId", "", [""]],
    ["_realGroup", grpNull, [grpNull]]
];

if (isNil "FLO_FormationState") then { throw "Formation skill requested before initialization"; };
if (isNull _realGroup) then { throw format ["Formation skill requested for null real group %1", _groupId]; };
private _index = FLO_FormationState get "groupToFormation";
if !(_groupId in _index) exitWith { false };
private _formation = (FLO_FormationState get "formations") get (_index get _groupId);
private _quality = (((_formation get "readiness") * 0.35) + ((_formation get "experience") * 0.65)) / 100;

{
    if (!isPlayer _x) then {
        _x setSkill ["aimingAccuracy", 0.18 + (_quality * 0.04)];
        _x setSkill ["aimingShake", 0.35 - (_quality * 0.12)];
        _x setSkill ["aimingSpeed", 0.40 + (_quality * 0.15)];
        _x setSkill ["spotDistance", 0.45 + (_quality * 0.20)];
        _x setSkill ["spotTime", 0.40 + (_quality * 0.20)];
        _x setSkill ["courage", 0.55 + (_quality * 0.30)];
        _x setSkill ["commanding", 0.45 + (_quality * 0.30)];
        _x setSkill ["reloadSpeed", 0.50 + (_quality * 0.25)];
        _x setSkill ["general", 0.50 + (_quality * 0.25)];
    };
} forEach units _realGroup;
_realGroup setVariable ["FLO_FormationId", _formation get "formationId", true];
_realGroup setVariable ["FLO_FormationName", _formation get "name", true];
true
