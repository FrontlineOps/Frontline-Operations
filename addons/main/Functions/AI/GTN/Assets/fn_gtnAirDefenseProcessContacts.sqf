/* Processes canonical and player aircraft contacts for virtualized AA groups. */
if (!isServer || {isNil "FLO_VirtualForceRegistry"}) exitWith { 0 };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _state = call FLO_fnc_gtnAirDefenseGetState;
private _processed = 0;

{
    private _airId = _x;
    private _airData = _y;
    if !((_airData get "groupType") in ["helicopter", "air", "jet"]) then { continue };
    if ((_airData get "unitCount") <= 0) then { continue };

    if (_airData get "isActive") then {
        private _realGroup = _airData get "realGroup";
        if (isNull _realGroup) then { continue };
        private _vehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
        if (_vehicles isEqualTo []) then { continue };
        [_vehicles select 0, _airData get "side"] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft;
        _processed = _processed + 1;
    } else {
        private _position = _airData get "position";
        private _mapSize = getNumber (configFile >> "CfgWorlds" >> worldName >> "mapSize");
        if ((_position select 0) < 0 || {(_position select 0) > _mapSize}) then { continue };
        if ((_airData get "waypoints") isEqualTo [] && {(_airData get "missionLock") == ""}) then { continue };
        [_airId, _position, _position] call FLO_fnc_gtnAirDefenseResolveVirtualEngagement;
        _processed = _processed + 1;
    };
} forEach _groups;

private _playerAircraft = [];
private _headlessClients = entities "HeadlessClient_F";
{
    if (!alive _x) then { continue };
    if (_x in _headlessClients) then { continue };
    private _vehicle = vehicle _x;
    if (_vehicle == _x || {!(_vehicle isKindOf "Air")}) then { continue };
    _playerAircraft pushBackUnique [_vehicle, side group _x];
} forEach allPlayers;
{
    _x params ["_aircraft", "_side"];
    [_aircraft, _side] call FLO_fnc_gtnAirDefenseActivateAgainstLiveAircraft;
    _processed = _processed + 1;
} forEach _playerAircraft;

private _lastContacts = _state get "lastLiveContactAt";
{
    private _aaId = _x;
    private _lastContactAt = _lastContacts get _aaId;
    if !(_aaId in _groups) then {
        _lastContacts deleteAt _aaId;
        continue;
    };
    if ((diag_tickTime - _lastContactAt) < (_state get "liveContactGraceSeconds")) then { continue };
    private _aaData = _groups get _aaId;
    if ((_aaData get "missionLock") == "AIR_DEFENSE") then {
        [_aaData] call FLO_fnc_virtualizationClearMissionLock;
    };
    _lastContacts deleteAt _aaId;
} forEach (keys _lastContacts);

_processed
