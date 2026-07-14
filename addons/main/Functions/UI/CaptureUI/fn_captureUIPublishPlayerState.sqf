/* Publishes viewer-relative Capture visibility and state to one player owner. */
params ["_player", "_objectiveMatch", ["_forceVisibility", false, [false]]];

private _uid = getPlayerUID _player;
if (_uid == "") exitWith { false };

private _objectiveId = "";
private _objective = createHashMap;
if (_objectiveMatch isNotEqualTo []) then {
    _objectiveMatch params ["_matchedId", "_matchedObjective"];
    _objectiveId = _matchedId;
    _objective = _matchedObjective;
};

private _previousObjectiveId = "";
private _previousPlayerNetId = "";
if (_uid in FLO_PlayerObjectiveStates) then {
    (FLO_PlayerObjectiveStates get _uid) params ["_storedObjectiveId", "_storedPlayerNetId"];
    _previousObjectiveId = _storedObjectiveId;
    _previousPlayerNetId = _storedPlayerNetId;
};

private _playerNetId = netId _player;
private _visibilityChanged = _forceVisibility
    || {_objectiveId != _previousObjectiveId}
    || {_playerNetId != _previousPlayerNetId};
private _clientOwner = owner _player;

if (_visibilityChanged) then {
    if (_objectiveId == "") then {
        ["FLO_CaptureUI_Hide", [], _clientOwner] call CBA_fnc_ownerEvent;
    } else {
        [
            "FLO_CaptureUI_Show",
            [_objective get "name", _objectiveId],
            _clientOwner
        ] call CBA_fnc_ownerEvent;
    };
};

FLO_PlayerObjectiveStates set [_uid, [_objectiveId, _playerNetId]];
if (_objectiveId == "") exitWith { true };

private _playerSide = side group _player;
if !(_playerSide in [west, east]) then {
    private _message = format ["Capture UI publisher received invalid campaign side %1", _playerSide];
    ["UI", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _bluforCount = _objective get "bluforCount";
private _opforCount = _objective get "opforCount";
private _friendlyCount = [_bluforCount, _opforCount] select (_playerSide isEqualTo east);
private _enemyCount = [_opforCount, _bluforCount] select (_playerSide isEqualTo east);
private _totalCount = _friendlyCount + _enemyCount;
private _ratio = if (_totalCount > 0) then { _friendlyCount / _totalCount } else { 0.5 };
private _objectiveOwner = [_objective get "owner"] call FLO_fnc_objectiveNormalizeOwner;
private _ownership = "NEUTRAL";
if (_objectiveOwner isEqualTo _playerSide) then {
    _ownership = "FRIENDLY";
} else {
    if (_objectiveOwner in [west, east]) then {
        _ownership = "ENEMY";
    };
};

["FLO_CaptureUI_Update", [
    _objectiveId,
    _ratio,
    _friendlyCount,
    _enemyCount,
    _ownership,
    [_playerSide] call FLO_fnc_sideKey,
    _objective get "captureState",
    _objective get "captureSecureProgress",
    _objective get "captureProgress"
], _clientOwner] call CBA_fnc_ownerEvent;

true
