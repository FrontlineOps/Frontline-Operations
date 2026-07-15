if (!isServer) exitWith { false };

private _claims = createHashMapFromArray [
    ["WEST", false],
    ["EAST", false]
];
private _restoringSave = FLO_IsLoadedSave;
private _initializationError = "";

try {
    if (FLO_IsLoadedSave) then {
        private _savedState = FLO_SavedGameData get "baseDeploymentState";
        if !(_savedState isEqualType createHashMap) then {
            throw format ["Saved base deployment state must be a HashMap, got %1", typeName _savedState];
        };
        private _missingFields = ["firstFOBClaimedBySide"] select { !(_x in _savedState) };
        if (_missingFields isNotEqualTo []) then {
            throw format ["Saved base deployment state is missing fields %1", _missingFields];
        };
        private _unexpectedFields = (keys _savedState) select { !(_x in ["firstFOBClaimedBySide"]) };
        if (_unexpectedFields isNotEqualTo []) then {
            throw format ["Saved base deployment state has unsupported fields %1", _unexpectedFields];
        };

        private _savedClaims = _savedState get "firstFOBClaimedBySide";
        [_savedClaims] call FLO_fnc_baseDeployValidateState;
        _claims set ["WEST", _savedClaims get "WEST"];
        _claims set ["EAST", _savedClaims get "EAST"];
    };

    {
        if (!isNull _x && {alive _x} && {(_x getVariable ["FLO_BaseType", ""]) == "FOB"}) then {
            private _side = _x getVariable ["FLO_BaseSide", sideUnknown];
            if !(_side in [west, east]) then {
                throw format ["Existing FOB at %1 has unsupported side %2", getPosATL _x, _side];
            };
            private _sideKey = [_side] call FLO_fnc_sideKey;
            if (_restoringSave && {!(_claims get _sideKey)}) then {
                throw format ["Current base deployment save has a living %1 FOB but an unclaimed first FOB entitlement", _sideKey];
            };
            _claims set [_sideKey, true];
        };
    } forEach FLO_CampaignBases;

    [_claims] call FLO_fnc_baseDeployValidateState;
} catch {
    _initializationError = _exception;
};

if (_initializationError != "") then {
    private _severity = [1, 2] select FLO_IsLoadedSave;
    private _context = ["initialization failed", "saved state was refused"] select FLO_IsLoadedSave;
    ["BASE", _severity, format ["Base deployment %1: %2", _context, _initializationError]] call FLO_fnc_log;
    throw _initializationError;
};

FLO_BaseFirstFOBClaimedBySide = _claims;
publicVariable "FLO_BaseFirstFOBClaimedBySide";
["BASE", 3, format ["Initialized first FOB claim state: %1", FLO_BaseFirstFOBClaimedBySide]] call FLO_fnc_log;

true
