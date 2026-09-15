/* Own the physical group's identity and empty-group notification until teardown. */
params ["_groupId", "_realGroup"];

private _oldHandler = _realGroup getVariable ["FLO_virtualEmptyHandler", -1];
if (_oldHandler >= 0) then {
    _realGroup removeEventHandler ["Empty", _oldHandler];
};
_realGroup setVariable ["FLO_virtualEmptyHandler", nil];
_realGroup setVariable ["FLO_virtualGroupId", _groupId];
if (_groupId == "") exitWith { true };

private _handler = _realGroup addEventHandler ["Empty", {
    params ["_realGroup"];
    private _groupId = _realGroup getVariable "FLO_virtualGroupId";
    [_groupId] call FLO_fnc_virtualizationRepairOrphanedActiveGroup;
}];
_realGroup setVariable ["FLO_virtualEmptyHandler", _handler];
true
