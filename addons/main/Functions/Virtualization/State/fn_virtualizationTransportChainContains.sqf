/*
 * Function: FLO_fnc_virtualizationTransportChainContains
 * Description:
 *   Walks carrier ancestry to detect a target group or an existing cycle.
 */

params [
    ["_startGroupId", "", [""]],
    ["_targetGroupId", "", [""]]
];

if (_startGroupId == "" || {_targetGroupId == ""}) then {
    throw "Transport ancestry checks require non-empty group IDs";
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _visited = createHashMap;
private _currentGroupId = _startGroupId;
private _containsTarget = false;

while {_currentGroupId != "" && {!_containsTarget}} do {
    if (_currentGroupId == _targetGroupId) then {
        _containsTarget = true;
    } else {
        if (_currentGroupId in _visited) then {
            throw format ["Existing transport cycle reaches group %1", _currentGroupId];
        };
        _visited set [_currentGroupId, true];

        private _groupData = _groups get _currentGroupId;
        if (isNil "_groupData") then {
            throw format ["Transport ancestry references missing group %1", _currentGroupId];
        };
        _currentGroupId = _groupData get "attachedTo";
    };
};

_containsTarget
