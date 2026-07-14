/*
 * Function: FLO_fnc_civilianGetHostileForcePool
 * Description:
 *   Returns the native opposing campaign side and infantry pool used for
 *   hostile civilian-mission responses.
 */

private _hostileSide = [FLO_ActivePlayerSide] call FLO_fnc_opposingSide;
private _hostileCatalog = FLO_FactionCatalog get ([_hostileSide] call FLO_fnc_sideKey);
private _unitPool = _hostileCatalog get "groundInfantryUnits";

if (_unitPool isEqualTo []) then {
    private _message = format [
        "No native infantry is available for civilian mission response side %1",
        [_hostileSide] call FLO_fnc_sideKey
    ];
    ["CIVILIANS", 1, _message] call FLO_fnc_log;
    throw _message;
};

[_hostileSide, _unitPool]
