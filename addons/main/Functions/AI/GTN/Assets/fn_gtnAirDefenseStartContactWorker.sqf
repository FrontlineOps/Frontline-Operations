/* Starts the server-owned paced contact worker for physical and virtual air defense. */
if (!isServer) exitWith { false };

private _state = call FLO_fnc_gtnAirDefenseGetState;
if ((_state get "contactWorkerPfhId") >= 0) exitWith { true };

private _pfhId = [{ call FLO_fnc_gtnAirDefenseProcessContacts }, 5, []] call CBA_fnc_addPerFrameHandler;
_state set ["contactWorkerPfhId", _pfhId];
["GTN Air Defense", 3, "Air-defense contact worker started"] call FLO_fnc_log;
true
