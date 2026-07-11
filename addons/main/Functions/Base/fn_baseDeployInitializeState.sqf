if (!isServer) exitWith { false };

private _claims = createHashMapFromArray [
    ["WEST", false],
    ["EAST", false]
];
private _loadedCurrentSchema = false;

if (FLO_IsLoadedSave) then {
    private _saveVersion = FLO_SavedGameData get "saveVersion";

    if (_saveVersion >= 22) then {
        _loadedCurrentSchema = true;
        private _savedState = FLO_SavedGameData get "baseDeploymentState";
        if !(_savedState isEqualType createHashMap) then {
            throw format ["Saved base deployment state must be a HashMap, got %1", typeName _savedState];
        };
        if ((_savedState get "schemaVersion") != 1) then {
            throw format ["Unsupported base deployment state schema %1", _savedState get "schemaVersion"];
        };

        private _savedClaims = _savedState get "firstFOBClaimedBySide";
        [_savedClaims] call FLO_fnc_baseDeployValidateState;
        _claims set ["WEST", _savedClaims get "WEST"];
        _claims set ["EAST", _savedClaims get "EAST"];
    } else {
        if (_saveVersion == 21) then {
            private _savedNetworks = FLO_SavedGameData get "logisticsNetworkBySide";
            if !(_savedNetworks isEqualType createHashMap) then {
                throw format ["Version 21 logisticsNetworkBySide must be a HashMap, got %1", typeName _savedNetworks];
            };

            {
                private _sideKey = _x;
                private _savedNetwork = _savedNetworks get _sideKey;
                if !(_savedNetwork isEqualType createHashMap) then {
                    throw format ["Version 21 logistics network for %1 must be a HashMap", _sideKey];
                };
                private _savedNodes = _savedNetwork get "nodes";
                if !(_savedNodes isEqualType createHashMap) then {
                    throw format ["Version 21 logistics nodes for %1 must be a HashMap", _sideKey];
                };

                {
                    private _node = _y;
                    if !(_node isEqualType createHashMap) then {
                        throw format ["Version 21 logistics node %1 must be a HashMap", _x];
                    };
                    if ((_node get "sideKey") == _sideKey && {(_node get "type") == "FOB"}) exitWith {
                        _claims set [_sideKey, true];
                    };
                } forEach _savedNodes;
            } forEach ["WEST", "EAST"];
        };

        if ("fobs" in FLO_SavedGameData) then {
            private _savedFOBs = FLO_SavedGameData get "fobs";
            if !(_savedFOBs isEqualType []) then {
                throw format ["Legacy saved FOB collection must be an Array, got %1", typeName _savedFOBs];
            };

            {
                if !(_x isEqualType createHashMap) then {
                    throw format ["Legacy saved FOB entry must be a HashMap, got %1", typeName _x];
                };
                private _sideKey = if ("baseSideKey" in _x) then { _x get "baseSideKey" } else { "WEST" };
                if !(_sideKey in ["WEST", "EAST"]) then {
                    throw format ["Legacy saved FOB has invalid side %1", _sideKey];
                };
                _claims set [_sideKey, true];
            } forEach _savedFOBs;
        };

        ["BASE", 2, format ["Migrated version %1 first FOB claims: %2", _saveVersion, _claims]] call FLO_fnc_log;
    };
};

{
    if (!isNull _x && {alive _x} && {(_x getVariable ["FLO_BaseType", ""]) == "FOB"}) then {
        private _side = _x getVariable ["FLO_BaseSide", sideUnknown];
        if !(_side in [west, east]) then {
            throw format ["Existing FOB at %1 has unsupported side %2", getPosATL _x, _side];
        };
        private _sideKey = [_side] call FLO_fnc_sideKey;
        if (_loadedCurrentSchema && {!(_claims get _sideKey)}) then {
            throw format ["Save schema 22 has a living %1 FOB but an unclaimed first FOB entitlement", _sideKey];
        };
        _claims set [_sideKey, true];
    };
} forEach FLO_CampaignBases;

[_claims] call FLO_fnc_baseDeployValidateState;
FLO_BaseFirstFOBClaimedBySide = _claims;
publicVariable "FLO_BaseFirstFOBClaimedBySide";
["BASE", 2, format ["Initialized first FOB claim state: %1", FLO_BaseFirstFOBClaimedBySide]] call FLO_fnc_log;

true
