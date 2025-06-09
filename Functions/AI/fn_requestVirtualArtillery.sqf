/*
    Function: FLO_fnc_requestVirtualArtillery

    Description:
    Wrapper function to request a fire mission from the artillery asset manager.
    Simplifies calling the manager from other systems such as the AI Commander.

    Parameters:
    _targetPos - Target position for the mission [Array]
    _rounds - Number of rounds to fire (default 6) [Number]

    Returns:
    Boolean - True if a mission was successfully scheduled
*/

params ["_targetPos", ["_rounds", 6]];

private _manager = call FLO_fnc_artilleryAssetManager;
_manager call ["_requestFireMission", [_targetPos, _rounds]];

