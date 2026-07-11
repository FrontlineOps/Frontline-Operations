params ["_treasury"];

if ("startingResources" in FLO_MissionConfig) exitWith {
    private _startingResources = FLO_MissionConfig get "startingResources";
    if !(_startingResources isEqualType 0 && {_startingResources == 5000}) then {
        throw format ["Invalid startingResources mission config value: %1", _startingResources];
    };
    _startingResources
};

if (!isNil "FLO_SavedGameData" && {(FLO_SavedGameData get "saveVersion") < 21}) exitWith { 5000 };

throw "Current mission config is missing required startingResources"
