/*
 * Function: FLO_fnc_campaignCollectOpportunities
 * Description:
 *   Maintains player-created local action records without redirecting the
 *   active operation.
 */

params ["_director"];

private _state = _director get "_state";
private _config = _director get "_config";
private _opportunities = _state get "opportunities";
private _activeObjectiveId = _state get "objectiveId";
private _now = dateToNumber date;
private _changed = false;
private _sampled = 0;

{
    private _player = _x;
    if (!alive _player) then { continue };

    private _side = side group _player;
    if !(_side in [west, east]) then { continue };

    private _objectiveId = [getPosATL _player] call FLO_fnc_campaignFindObjectiveAtPosition;
    if (_objectiveId == "" || {_objectiveId == _activeObjectiveId}) then { continue };

    private _objective = FLO_Objectives get _objectiveId;
    private _owner = _objective get "owner";
    private _integrationState = _objective get "campaignIntegrationState";
    private _status = "";

    if (_owner isEqualTo _side) then {
        if (_integrationState == "FOOTHOLD") then {
            _status = "FOOTHOLD";
        } else {
            if ((_objective get "underAttack") || {_objective get "contested"}) then {
                _status = "LOCAL_DEFENSE";
            };
        };
    } else {
        _status = ["CONTACT", "ASSAULT"] select (
            (_objective get "contested")
            || {(_objective get "captureState") in ["clearing", "securing"]}
        );
    };

    if (_status == "") then { continue };

    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    private _key = _sideKey + "|" + _objectiveId;
    private _record = createHashMap;

    if (_key in _opportunities) then {
        _record = _opportunities get _key;
        if ((_record get "status") != _status) then { _changed = true; };
        _record set ["status", _status];
        _record set ["lastSeenAtDateNum", _now];
        _record set ["sampleCount", (_record get "sampleCount") + 1];
    } else {
        _record = createHashMapFromArray [
            ["sideKey", _sideKey],
            ["objectiveId", _objectiveId],
            ["status", _status],
            ["firstSeenAtDateNum", _now],
            ["lastSeenAtDateNum", _now],
            ["sampleCount", 1]
        ];
        _opportunities set [_key, _record];
        _changed = true;
    };

    _sampled = _sampled + 1;
} forEach allPlayers;

private _expireSeconds = _config get "opportunityExpireSeconds";
{
    private _record = _opportunities get _x;
    private _ageSeconds = [_record get "lastSeenAtDateNum", _now] call FLO_fnc_dateNumberDeltaSeconds;
    if (_ageSeconds > _expireSeconds) then {
        _opportunities deleteAt _x;
        _changed = true;
    };
} forEach +(keys _opportunities);

if (_changed) then {
    _state set ["revision", (_state get "revision") + 1];
};

createHashMapFromArray [
    ["sampled", _sampled],
    ["tracked", count _opportunities],
    ["changed", _changed]
]
