/*
 * Function: FLO_fnc_civilianRequestMission
 * Description: 
 *   Handles player request to help civilians ("Offer Help" action).
 *   Can trigger hostile responses (Engineers) or start a new mission via Manager.
 *
 * Arguments:
 *   0: Civilian Unit <OBJECT>
 */

params ["_civilian"];

// Hostile Engineer Logic (Legacy)
// 66% chance of hostile response if unit is an engineer
private _isEngineer = _civilian getUnitTrait "engineer";
if (_isEngineer && (random 1 > 0.33)) then {
    private _hostileLines = [
        "We Don't Need Your Help Outsider, Move away, GOD Damn you ALL !!!",
        "Wanna Help ? make alive My little Brother that you Killed, Fuck off you Bastard, GOD kill you ALL !!!",
        "You will Pay for what you have done to our Country, I dont tell you shit !!!",
        "We Dont need your Help, JUST FUCK OFF !!!",
        "Your Men Caused my Innocent brothers and sisters Suffer and Die, Fuck you, FUCK YOU ALL !!!"
    ];
    ["Civilian", selectRandom _hostileLines] remoteExec ["BIS_fnc_showSubtitle"];
} else {
    // Attempt to start a mission
    private _missionId = [["NEXT_MISSION"] call FLO_fnc_civilianMissionManager] param [0, 0];
    
    // If mission initiated successfully
    if (!isNil "_missionId" && {_missionId > 0}) then {
        // Show context-specific dialogue
        private _line = switch (_missionId) do {
            case 1: { "Ive heard some of you are Engineers, One of Locals Troubled his Vehicle somewhere Along the Road, Think You can Help?" };
            case 2: { "This Neighborhood Runs low on Supplies and the IDAP does not Accept the Risk, Can your Guys help them?" };
            case 3: { "our Neighbors Found a Minefield the hard way near this Area, Can Your Engineers take a look at it ?" };
            case 4: { "I know you were Looking for Insurgents, They have been seen along these roads few nights, Can you Create Checkpoints ?" };
            default { "We have some trouble nearby, can you help?" };
        };
        ["Civilian", _line] remoteExec ["BIS_fnc_showSubtitle"];
    } else {
        // Mission failed to start (likely one already active)
        private _busyLines = [
            "We are okay for now, thank you.",
            "Someone else is already helping us, I think.",
            "I haven't heard of any trouble recently.",
            "Maybe ask someone else in the next town."
        ];
        ["Civilian", selectRandom _busyLines] remoteExec ["BIS_fnc_showSubtitle"];
    };
};