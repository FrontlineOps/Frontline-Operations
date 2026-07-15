/* Applies one authorized remote artillery mission to reported virtual targets. */
params [["_missionRecord", nil]];

if (!isServer) then { throw "Virtual artillery effects are server-owned"; };
if (isNil "_missionRecord") then { throw "Virtual artillery effect requires a mission record"; };

private _artillerySide = _missionRecord get "side";
if !(_artillerySide in [east, west]) then {
    throw format ["Virtual artillery mission %1 has invalid side %2", _missionRecord get "missionId", _artillerySide];
};

private _enemySide = [east, west] select (_artillerySide isEqualTo east);
private _targetPos = _missionRecord get "targetPos";
private _plannedRounds = _missionRecord get "plannedRounds";
private _accuracy = _missionRecord get "accuracy";
private _contactState = _missionRecord get "contactState";
private _contactConfidence = _missionRecord get "contactConfidence";
private _contactAgeSeconds = _missionRecord get "contactAgeSeconds";
private _targetGroupIds = +(_missionRecord get "targetGroupIds");
private _exactTargets = _targetGroupIds isNotEqualTo [];
private _impactRadius = (((_accuracy max 80) * 3) max 300) min 700;
private _groups = call FLO_fnc_virtualizationGetGroupMap;

if (!_exactTargets) then {
    _targetGroupIds = ["queryRadius", [_targetPos, _impactRadius]] call FLO_fnc_virtualizationSpatialIndex;
};

private _contactFactor = switch (_contactState) do {
    case "ENGAGEMENT": { 1 };
    case "COUNTER_BATTERY": { 1.15 };
    case "OBSERVED": { 1.1 };
    case "FRONTLINE_FRESH": { 1 };
    case "FRONTLINE_STALE": { 0.65 };
    default { 0.7 };
};
if ((_contactState find "FRONTLINE_") == 0) then {
    _contactFactor = _contactFactor
        * ((_contactConfidence max 0.25) min 1)
        * linearConversion [0, 900, _contactAgeSeconds, 1, 0.35, true];
};
private _candidates = [];

{
    private _groupId = _x;
    if !(_groupId in _groups) then { continue };

    private _groupData = _groups get _groupId;
    if ((_groupData get "side") isNotEqualTo _enemySide) then { continue };
    if (_groupData get "isActive") then { continue };
    if (([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) != "") then { continue };
    if ((_groupData get "unitCount") <= 0) then { continue };

    private _groupType = _groupData get "groupType";
    if !(_groupType in ["infantry", "motorized", "mechanized", "armor", "mobile_aa", "artillery", "static_aa"]) then { continue };

    private _distance = (_groupData get "position") distance2D _targetPos;
    if (_distance > _impactRadius) then { continue };

    private _exposure = switch (_groupType) do {
        case "artillery": { 1.5 };
        case "static_aa": { 1.4 };
        case "motorized": { 1.25 };
        case "mobile_aa": { 1.1 };
        case "mechanized": { 0.7 };
        case "armor": { 0.4 };
        default { 1 };
    };
    private _order = _groupData get "commanderOrder";
    if (_order == "ATTACK") then { _exposure = _exposure * 1.15; };
    if (_order in ["DEFEND", "GARRISON"]) then { _exposure = _exposure * 0.8; };

    private _priority = (_exposure * 1000) + ((_groupData get "unitCount") * 10) - _distance;
    _candidates pushBack [-_priority, _distance, _groupId, _exposure];
} forEach _targetGroupIds;

private _result = createHashMapFromArray [
    ["totalLosses", 0],
    ["groupsHit", 0],
    ["groupsDestroyed", 0]
];
if (_candidates isEqualTo []) exitWith { _result };

_candidates sort true;
private _targetCount = ((ceil (_plannedRounds / 3)) max 1) min 3 min (count _candidates);
private _accuracyFactor = ((100 / (_accuracy max 1)) max 0.75) min 1.35;

for "_index" from 0 to (_targetCount - 1) do {
    (_candidates select _index) params ["_priority", "_distance", "_groupId", "_exposure"];
    if !(_groupId in _groups) then { continue };

    private _groupData = _groups get _groupId;
    private _currentCount = _groupData get "unitCount";
    private _distanceFactor = (1 - ((_distance / _impactRadius) * 0.55)) max 0.4;
    private _distributionFactor = 1 / (1 + (_index * 0.4));
    private _rawLoss = _plannedRounds * 0.9 * _accuracyFactor * _contactFactor * _exposure * _distanceFactor * _distributionFactor;
    private _requestedLoss = ((round _rawLoss) max 1) min _currentCount;
    private _appliedLoss = [_groupId, _requestedLoss] call FLO_fnc_gtnCombatApplyGroupLoss;
    if (_appliedLoss <= 0) then { continue };

    _result set ["totalLosses", (_result get "totalLosses") + _appliedLoss];
    _result set ["groupsHit", (_result get "groupsHit") + 1];
    if (_appliedLoss >= _currentCount) then {
        _result set ["groupsDestroyed", (_result get "groupsDestroyed") + 1];
    };
};

_missionRecord set ["virtualLosses", _result get "totalLosses"];
_missionRecord set ["virtualGroupsHit", _result get "groupsHit"];
_missionRecord set ["virtualGroupsDestroyed", _result get "groupsDestroyed"];
["FLO_GTN_VirtualArtilleryEffect", [_missionRecord, _result]] call CBA_fnc_localEvent;

_result
