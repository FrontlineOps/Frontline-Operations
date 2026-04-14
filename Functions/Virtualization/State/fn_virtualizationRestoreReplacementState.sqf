/*
 * Function: FLO_fnc_virtualizationRestoreReplacementState
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearReplacementTransit;
switch (_savedData get "replacementState") do {
    case "REINFORCE": {
        [
            _groupData,
            _savedData get "reinforcementTargetPos",
            _savedData get "reinforcementRequestedObjective",
            _savedData get "reinforcementDeliveryObjective"
        ] call FLO_fnc_virtualizationMarkReinforcementTransit;
    };
    case "AA_DEPLOY": {
        [
            _groupData,
            _savedData get "reinforcementTargetPos",
            _savedData get "reinforcementRequestedObjective",
            _savedData get "reinforcementDeliveryObjective"
        ] call FLO_fnc_virtualizationMarkStaticAAReplacementTransit;
    };
};

true
