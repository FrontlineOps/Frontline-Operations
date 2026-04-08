/*
 * Function: FLO_fnc_requestSavedPlayerState
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-side bridge that looks up a saved player state by UID and sends
 *   it to the owning client for local application.
 *
 * Arguments:
 *   0: Player unit <OBJECT>
 *
 * Returns:
 *   BOOL
 */

if (!isServer) exitWith { false };

params [["_player", objNull, [objNull]]];

private _uid = getPlayerUID _player;
if (_uid isEqualTo "") exitWith { false };
if (isNil "FLO_PersistentPlayerStates") exitWith { false };

private _players = FLO_PersistentPlayerStates;
if !(_uid in _players) exitWith { false };

private _state = _players get _uid;
private _savedSideKey = _state get "sideKey";
private _liveSideKey = ([(side group _player)] call FLO_fnc_gtnSideContext) get "sideKey";

if (_savedSideKey != _liveSideKey) exitWith {
    ["PERSIST", 2, format [
        "Saved player state side mismatch for %1 (%2 saved, %3 live) - not restoring",
        name _player,
        _savedSideKey,
        _liveSideKey
    ]] call FLO_fnc_log;
    false
};

[_state] remoteExecCall ["FLO_fnc_applySavedPlayerState", owner _player];
["PERSIST", 3, format ["Queued saved player state restore for %1 (%2)", name _player, _uid]] call FLO_fnc_log;
true
