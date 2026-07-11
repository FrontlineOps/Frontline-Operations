/* Allows support for integrated territory or a captured operation target. */
params [
    ["_side", sideUnknown, [east]],
    ["_objectiveId", "", [""]]
];

if ([_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) exitWith { true };
if (isNil "FLO_CampaignDirector") then {
    throw "FLO_fnc_campaignCanSupportObjective: campaign director is not initialized";
};

private _state = FLO_CampaignDirector call ["_getState", []];
private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _canSupport = false;
{
    private _operation = _y;
    if (
        (_operation get "objectiveId") == _objectiveId
        && {(_operation get "attackerSideKey") == _sideKey}
        && {(_operation get "phase") in ["SECURE", "CONSOLIDATE"]}
    ) exitWith {
        _canSupport = true;
    };
} forEach (_state get "operations");
_canSupport
