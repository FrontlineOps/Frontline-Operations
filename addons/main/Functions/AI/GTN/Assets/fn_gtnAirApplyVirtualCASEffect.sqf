/* Applies one authorized virtual CAS mission to exact reported targets. */
params [["_missionRecord", nil]];

if (!isServer) then { throw "Virtual CAS effects are server-owned"; };
if (isNil "_missionRecord") then { throw "Virtual CAS requires a mission record"; };

private _airSide = _missionRecord get "side";
private _enemySide = [east, west] select (_airSide isEqualTo east);
private _airType = _missionRecord get "aircraftGroupType";
private _targetIds = +(_missionRecord get "targetGroupIds");
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _candidates = [];

{
    private _groupId = _x;
    if !(_groupId in _groups) then { continue };
    private _groupData = _groups get _groupId;
    if ((_groupData get "side") isNotEqualTo _enemySide) then { continue };
    if (_groupData get "isActive") then { continue };
    if ((_groupData get "unitCount") <= 0) then { continue };

    private _groupType = _groupData get "groupType";
    if !(_groupType in ["infantry", "motorized", "mechanized", "armor", "mobile_aa", "artillery", "static_aa"]) then { continue };

    private _exposure = if (_airType == "jet") then {
        switch (_groupType) do {
            case "artillery": { 1.4 };
            case "armor": { 1.3 };
            case "static_aa": { 1.3 };
            case "mechanized": { 1.2 };
            case "mobile_aa": { 1.1 };
            case "motorized": { 1 };
            default { 0.6 };
        }
    } else {
        switch (_groupType) do {
            case "infantry": { 1.3 };
            case "motorized": { 1.2 };
            case "artillery": { 1.1 };
            case "static_aa";
            case "mobile_aa": { 0.9 };
            case "mechanized": { 0.6 };
            default { 0.35 };
        }
    };
    if ((_groupData get "commanderOrder") == "ATTACK") then { _exposure = _exposure * 1.15; };
    if ((_groupData get "commanderOrder") in ["DEFEND", "GARRISON"]) then { _exposure = _exposure * 0.8; };
    _candidates pushBack [-((_exposure * 1000) + (_groupData get "unitCount")), _groupId, _exposure];
} forEach _targetIds;

private _result = createHashMapFromArray [["totalLosses", 0], ["groupsHit", 0], ["groupsDestroyed", 0]];
if (_candidates isEqualTo []) exitWith { _result };

_candidates sort true;
private _targetCount = 2 min count _candidates;
private _baseLoss = [3, 5] select (_airType == "jet");
for "_index" from 0 to (_targetCount - 1) do {
    (_candidates select _index) params ["_priority", "_groupId", "_exposure"];
    if !(_groupId in _groups) then { continue };
    private _groupData = _groups get _groupId;
    private _currentCount = _groupData get "unitCount";
    private _requestedLoss = ((round (_baseLoss * _exposure / (1 + (_index * 0.35)))) max 1) min _currentCount;
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
["FLO_GTN_VirtualCASEffect", [_missionRecord, _result]] call CBA_fnc_localEvent;
_result
