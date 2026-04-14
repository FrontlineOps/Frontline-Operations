/*
 * Function: FLO_fnc_gtnBuildObservedRealEnemyTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes one actually observed real enemy contact into GTN engagement
 *   target data when no virtual enemy group resolves for the report. This is
 *   used for player-led enemy groups so opportunistic engagements stay
 *   intel-driven instead of relying on omniscient scans.
 *
 * Arguments:
 * 0: Observed source object <OBJECT>
 * 1: Contact position <ARRAY>
 * 2: Contact time <NUMBER>
 * 3: Contact strength <NUMBER>
 * 4: Contact confidence <NUMBER>
 *
 * Return Value:
 * HASHMAP - Empty when invalid, otherwise contains a normalized target entry
 *           with "groupId", "position", "groupType", "unitCount",
 *           "commanderOrder", "lastSeen", "confidence", "contactCount",
 *           "objectiveIds", "isPlayerControlled"
 */

params [
    ["_observedObject", objNull, [objNull]],
    ["_contactPos", [], [[]]],
    ["_contactTime", -1, [0]],
    ["_contactStrength", 1, [0]],
    ["_contactConfidence", 0, [0]]
];

private _target = createHashMap;
if (isNull _observedObject || {!alive _observedObject}) exitWith { _target };

private _contextObject = vehicle _observedObject;
if (isNull _contextObject) then {
    _contextObject = _observedObject;
};

private _localUnits = [];

if (_contextObject isKindOf "Man") then {
    private _observedGroup = group _contextObject;
    if (isNull _observedGroup) exitWith { _target };

    {
        if (!alive _x) then { continue };
        if ((_x distance2D _contactPos) > 80) then { continue };
        _localUnits pushBack _x;
    } forEach (units _observedGroup);
} else {
    {
        private _unit = _x select 0;
        if (!alive _unit) then { continue };
        _localUnits pushBackUnique _unit;
    } forEach (fullCrew [_contextObject, "", true]);

    if (count _localUnits == 0) then {
        {
            if (!alive _x) then { continue };
            _localUnits pushBackUnique _x;
        } forEach (crew _contextObject);
    };
};

if (count _localUnits == 0) exitWith { _target };

private _playerUnits = _localUnits select { isPlayer _x };
if (count _playerUnits == 0) exitWith { _target };

private _playerLeader = _playerUnits select 0;
private _playerGroup = group _playerLeader;
if (isNull _playerGroup) exitWith { _target };

private _groupLeader = leader _playerGroup;
if (isNull _groupLeader || {!alive _groupLeader}) then {
    _groupLeader = _playerLeader;
};

private _groupNetId = netId _groupLeader;
if (_groupNetId == "") exitWith { _target };

private _targetPos = if (count _contactPos >= 2) then {
    +_contactPos
} else {
    getPosATL _contextObject
};

private _groupType = "infantry";
if !(_contextObject isKindOf "Man") then {
    private _weaponNames = (weapons _contextObject) apply { toUpper _x };
    private _hasAAWeapon = {
        (_x find "AA" >= 0) || {(_x find "SAM" >= 0)}
    } count _weaponNames > 0;

    if (count (getArtilleryAmmo [_contextObject]) > 0) then {
        _groupType = "artillery";
    } else {
        if (_hasAAWeapon) then {
            _groupType = if (_contextObject isKindOf "StaticWeapon") then { "static_aa" } else { "mobile_aa" };
        } else {
            private _cfgVehicle = configFile >> "CfgVehicles" >> typeOf _contextObject;
            private _transportSoldier = getNumber (_cfgVehicle >> "transportSoldier");

            if (_contextObject isKindOf "Tank") then {
                _groupType = if (_transportSoldier >= 4) then { "mechanized" } else { "armor" };
            } else {
                if (
                    _contextObject isKindOf "Wheeled_APC_F" ||
                    {_contextObject isKindOf "Tracked_APC_F"} ||
                    {_transportSoldier >= 4}
                ) then {
                    _groupType = "mechanized";
                } else {
                    if (_contextObject isKindOf "Car" || {_contextObject isKindOf "Truck_F"}) then {
                        _groupType = "motorized";
                    };
                };
            };
        };
    };
};

private _unitCount = ((count _localUnits) max (ceil _contactStrength)) max 1;

createHashMapFromArray [
    ["groupId", format ["real_%1", (_groupNetId splitString ":") joinString "_"]],
    ["position", _targetPos],
    ["lastSeen", _contactTime],
    ["confidence", _contactConfidence],
    ["contactCount", 0],
    ["groupType", _groupType],
    ["unitCount", _unitCount],
    ["commanderOrder", "MOVE"],
    ["objectiveIds", []],
    ["isPlayerControlled", true]
]
