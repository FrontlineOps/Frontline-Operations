params [["_sideKey", "", [""]]];

private _fundingIds = ([_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds) select {
    ((FLO_Objectives get _x) get "developmentProject") get "state" == "FUNDING"
};
private _maximum = FLO_ObjectiveDevelopmentConfig get "maximumFundingProjects";
if ((count _fundingIds) > _maximum) then {
    throw format ["Side %1 owns %2 funding projects, above maximum %3: %4", _sideKey, count _fundingIds, _maximum, _fundingIds];
};
if (_fundingIds isEqualTo []) exitWith { "" };
_fundingIds select 0
