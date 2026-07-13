if (!isServer) exitWith { false };

private _changed = false;
private _nextInvestmentAt = FLO_ObjectiveDevelopmentRuntime get "nextInvestmentAt";
private _investmentInterval = FLO_ObjectiveDevelopmentConfig get "investmentInterval";

{
    private _side = _x;
    private _sideKey = [_side] call FLO_fnc_sideKey;
    private _activeObjectiveIds = [_sideKey] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds;
    {
        if ([_side, _x] call FLO_fnc_objectiveDevelopmentProcessProject) then { _changed = true; };
    } forEach _activeObjectiveIds;

    if (diag_tickTime >= (_nextInvestmentAt get _sideKey)) then {
        _nextInvestmentAt set [_sideKey, diag_tickTime + _investmentInterval];
        private _fundingObjectiveId = [_sideKey] call FLO_fnc_objectiveDevelopmentGetFundingObjectiveId;
        if (_fundingObjectiveId != "" && {[_side, _fundingObjectiveId] call FLO_fnc_objectiveDevelopmentFundProject}) then {
            _changed = true;
        };

        if (([_sideKey] call FLO_fnc_objectiveDevelopmentGetFundingObjectiveId) == "") then {
            private _candidate = [_side] call FLO_fnc_objectiveDevelopmentSelectInvestment;
            if ((keys _candidate) isNotEqualTo [] && {
                [_side, _candidate get "objectiveId", _candidate get "branch"] call FLO_fnc_objectiveDevelopmentStartProject
            }) then {
                _changed = true;
            };
        };
    };
} forEach [west, east];

_changed
