/*
 * Function: FLO_fnc_virtualizationRestoreCommanderState
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
private _commanderOrder = _savedData get "commanderOrder";
if (_commanderOrder == "") exitWith { true };

[_groupData, _commanderOrder] call FLO_fnc_virtualizationSetCommanderOrder;
_groupData set ["orderTargetPos", _savedData get "orderTargetPos"];
_groupData set ["orderMode", _savedData get "orderMode"];
_groupData set ["attackObjective", _savedData get "attackObjective"];
if ("campaignOperationId" in _savedData) then {
    _groupData set ["campaignOperationId", _savedData get "campaignOperationId"];
};
_groupData set ["defendObjective", _savedData get "defendObjective"];
_groupData set ["defendLeaseIssuedAt", _savedData get "defendLeaseIssuedAt"];
_groupData set ["defendLeaseUntil", _savedData get "defendLeaseUntil"];
_groupData set ["garrisonObjective", _savedData get "garrisonObjective"];
_groupData set ["garrisonPosition", _savedData get "garrisonPosition"];

true
