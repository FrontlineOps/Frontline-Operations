/*
 * Function: FLO_fnc_civilianInvestigate
 * Description:
 *   Handles civilian investigation interaction logic (dialogue, reputation, resource cost, etc).
 * Arguments:
 *   0: Civilian unit <OBJECT>
 * Returns: Nothing
 * Usage: [unit] call FLO_fnc_civilianInvestigate;
 */

params ["_civilian"];

// Hostile Engineer Check
private _isEngineer = _civilian getUnitTrait "engineer";
if (_isEngineer && (random 1 > 0.33)) exitWith {
    private _complMessage = selectRandom [
        "DEATH TO OUTSIDERS, DEATH TO OUTSIDERS !!!",
        "Walk Away Bastards. . .You Just Bring Chaos and Destruction !!!",
        "You will Pay for what you have done to our Country, I dont tell you shit !!!",
        "May GOD Save us from Your Wicked chains you Devils, May GOD Dawn you all !!!",
        "Your Men Caused my Innocent brothers and sisters Suffer and Die, FUCK YOU ALL !!!"
    ];
    ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
};

// Resource Check
private _money = FLO_MoneyHandle getOrDefault ["value", 0];
if (_money < 5) exitWith {
    hint "Not enough Resources (Required: 5)";
};

// Cooperation Chance Calculation
private _repScore = FLO_ReputationHandle getOrDefault ["value", 0];
private _chance = if (_repScore > 10) then { 0.6 } else { 0.3 };

// Attempt Interaction
if (random 1 < _chance) then {
    FLO_MoneyHandle set ["value", _money - 5];
    publicVariable "FLO_MoneyHandle";
    
    [] call FLO_fnc_civilianIntel;
    
    private _okLines = [
        "Sure, Let me Show you the way!",
        "We appericiate your Efforts for our Homeland, let me Help you!",
        "Yes, Come, I know Some !"
    ];
    ["Civilian", selectRandom _okLines] remoteExec ["BIS_fnc_showSubtitle"];

} else {
    private _refuseLines = [
        "We Dont talk to Strangers!",
        "I don't know much about this Region!",
        "Sorry but I dont Trust you Outsiders!",
        "Maybe that Man there can Help you, He has been with the Army years ago !"
    ];
    ["Civilian", selectRandom _refuseLines] remoteExec ["BIS_fnc_showSubtitle"];
};