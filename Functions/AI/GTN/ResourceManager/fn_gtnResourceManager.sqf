/*
 * Function: FLO_fnc_gtnResourceManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes and manages dual GTN commanders (EAST/WEST).
 *
 * Arguments: None
 * Return Value: GTN Resource Manager HashMap Object <HASHMAP>
 */

["GTN Resource Manager", 3, "Starting GTN Resource Manager"] call FLO_fnc_log;

private _config = call FLO_fnc_gtnConfig;

private _resourceManager = createHashMapObject [[
    ["_config", _config],
    ["_gtnCommander", nil], // Backward compatibility alias (EAST commander)
    ["_gtnCommandersBySide", createHashMap],
    ["_virtGroupRemovedEH", -1],
    ["_dirtyEventEhIds", createHashMap],
    ["_loopPfhsBySide", createHashMap],

    ["_sideKey", {
        params ["_side"];
        if (_side isEqualTo east) exitWith { "EAST" };
        if (_side isEqualTo west) exitWith { "WEST" };
        "EAST"
    }],

    ["_getCommanderBySide", {
        params [["_side", east]];
        private _key = _self call ["_sideKey", [_side]];
        (_self get "_gtnCommandersBySide") get _key
    }],

    ["_getAllCommanders", {
        _self get "_gtnCommandersBySide"
    }],

    ["_onVirtualGroupRemoved", {
        params ["_groupId"];
        {
            private _cmdr = _y;
            _cmdr call ["_onVirtualGroupRemoved", [_groupId]];
        } forEach (_self get "_gtnCommandersBySide");
    }],

    ["_bindVirtualizationEvents", {
        private _ehId = _self get "_virtGroupRemovedEH";
        if (_ehId >= 0) exitWith {};

        missionNamespace setVariable ["FLO_GTN_ResourceManagerRef", _self];
        private _newEhId = ["FLO_Virtualization_GroupRemoved", {
            params ["_groupId"];
            private _mgr = missionNamespace getVariable "FLO_GTN_ResourceManagerRef";
            _mgr call ["_onVirtualGroupRemoved", [_groupId]];
        }] call CBA_fnc_addEventHandler;

        _self set ["_virtGroupRemovedEH", _newEhId];
    }],

    ["_markCommanderDirty", {
        params [["_side", sideUnknown], ["_reason", "", [""]], ["_payload", [], [[]]]];
        if !(_side in [east, west]) exitWith { false };

        private _commander = _self call ["_getCommanderBySide", [_side]];
        if (isNil "_commander") exitWith { false };

        [_commander, _reason, _payload] call FLO_fnc_gtnMarkCommanderStateDirty;
    }],

    ["_bindDirtyEvents", {
        private _ehIds = _self get "_dirtyEventEhIds";
        if (count (keys _ehIds) > 0) exitWith {};

        missionNamespace setVariable ["FLO_GTN_ResourceManagerRef", _self];

        _ehIds set ["objectiveFlipped", ["FLO_Objective_Flipped", {
            params ["_objectiveId", "_previousOwner", "_newOwner"];

            private _mgr = missionNamespace getVariable "FLO_GTN_ResourceManagerRef";
            if (isNil "_mgr") exitWith {};

            if (_previousOwner in [east, west]) then {
                _mgr call ["_markCommanderDirty", [_previousOwner, "OBJECTIVE_FLIPPED", [_objectiveId, _previousOwner, _newOwner]]];
            };
            if (_newOwner in [east, west]) then {
                _mgr call ["_markCommanderDirty", [_newOwner, "OBJECTIVE_FLIPPED", [_objectiveId, _previousOwner, _newOwner]]];
            };
        }] call CBA_fnc_addEventHandler];

        _ehIds set ["supplyChainChanged", ["FLO_Logistics_SupplyChainChanged", {
            params ["_managedSide", "_hqObjectiveId", "_nodeIds", "_signature"];

            private _mgr = missionNamespace getVariable "FLO_GTN_ResourceManagerRef";
            if (isNil "_mgr") exitWith {};

            _mgr call ["_markCommanderDirty", [_managedSide, "SUPPLY_CHAIN_CHANGED", [_hqObjectiveId, _nodeIds, _signature]]];
        }] call CBA_fnc_addEventHandler];

        _ehIds set ["artilleryMissionStateChanged", ["FLO_GTN_ArtilleryMissionStateChanged", {
            params ["_side", "_missionId", "_state"];

            private _mgr = missionNamespace getVariable "FLO_GTN_ResourceManagerRef";
            if (isNil "_mgr") exitWith {};

            _mgr call ["_markCommanderDirty", [_side, "ARTILLERY_STATE_CHANGED", [_missionId, _state]]];
        }] call CBA_fnc_addEventHandler];
    }],

    ["_startCommanderLoop", {
        params ["_gtn"];
        if (isNil "_gtn") exitWith {};
        private _sideKey = _gtn get "_sideKey";
        private _interval = _gtn get "_updateInterval";
        private _pfhs = _self get "_loopPfhsBySide";

        if (_sideKey in _pfhs) exitWith {
            ["GTN", 3, format["%1 execution loop already active", _sideKey]] call FLO_fnc_log;
        };

        // Deterministic phase offset so both commanders do not spike on the same frame.
        private _staggerDelay = if (_sideKey isEqualTo "WEST") then { _interval * 0.5 } else { 0 };
        if (_staggerDelay > 0) then {
            ["GTN", 3, format["%1 commander stagger delay: %2s", _sideKey, _staggerDelay]] call FLO_fnc_log;
        };

        [_self, _gtn, _sideKey, _interval] spawn {
            params ["_mgr", "_commander", "_sideKey", "_interval"];
            private _staggerDelay = if (_sideKey isEqualTo "WEST") then { _interval * 0.5 } else { 0 };
            if (_staggerDelay > 0) then { sleep _staggerDelay; };

            ["GTN", 3, format["Starting %1 execution loop (%2s, PFH)", _sideKey, _interval]] call FLO_fnc_log;

            private _pfhId = [{
                params ["_args", "_pfhId"];
                _args params ["_mgr", "_cmdr", "_sKey"];

                if ((_cmdr get "_isRunning") != 1) exitWith {
                    [_pfhId] call CBA_fnc_removePerFrameHandler;
                    private _pfhs = _mgr get "_loopPfhsBySide";
                    _pfhs deleteAt _sKey;
                    ["GTN", 3, format["Stopped %1 execution loop", _sKey]] call FLO_fnc_log;
                };

                _cmdr call ["_update", []];
            }, _interval, [_mgr, _commander, _sideKey]] call CBA_fnc_addPerFrameHandler;

            private _pfhs = _mgr get "_loopPfhsBySide";
            _pfhs set [_sideKey, _pfhId];
        };
    }],

    ["_initializeSideCommander", {
        params ["_side"];

        private _key = _self call ["_sideKey", [_side]];
        private _existing = (_self get "_gtnCommandersBySide") get _key;
        if (!isNil "_existing") exitWith { _existing };

        private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
        private _gtn = [_self, _sideCtx] call FLO_fnc_gtnCommander;

        if (!isNil "_gtn") then {
            (_self get "_gtnCommandersBySide") set [_key, _gtn];
            _gtn call ["_start", []];
            _self call ["_startCommanderLoop", [_gtn]];
            ["GTN Resource Manager", 2, format["%1 commander started", _key]] call FLO_fnc_log;
        } else {
            ["GTN Resource Manager", 1, format["Failed to initialize %1 commander", _key]] call FLO_fnc_log;
        };

        _gtn
    }],

    ["_initializeGTN", {
        ["GTN Resource Manager", 3, "Initializing dual GTN subsystem"] call FLO_fnc_log;

        _self call ["_bindVirtualizationEvents", []];

        private _map = _self get "_gtnCommandersBySide";
        if (count (keys _map) > 0) exitWith {
            ["GTN Resource Manager", 3, "Dual GTN already initialized"] call FLO_fnc_log;
        };

        private _sides = FLO_MissionSides;
        {
            if (_x in [east, west]) then {
                _self call ["_initializeSideCommander", [_x]];
            };
        } forEach _sides;

        // Backward compatibility: preserve singleton field as EAST commander.
        _self set ["_gtnCommander", _self call ["_getCommanderBySide", [east]]];

        // Keep commander objects server-local. They contain circular references
        // and are not safe to publicVariable.
        FLO_GTN_CommandersBySide = _self get "_gtnCommandersBySide";
        _self call ["_bindDirtyEvents", []];

        // Publish only lightweight side status for clients/debug UI.
        private _pubState = createHashMapFromArray [
            ["EAST", !isNil {(_self get "_gtnCommandersBySide") get "EAST"}],
            ["WEST", !isNil {(_self get "_gtnCommandersBySide") get "WEST"}]
        ];
        FLO_GTN_CommandersBySideState = _pubState;
        publicVariable "FLO_GTN_CommandersBySideState";

        ["GTN Resource Manager", 2, format["Dual GTN ready (%1 commanders)", count (keys (_self get "_gtnCommandersBySide"))]] call FLO_fnc_log;
    }]
]];

// Start GTN immediately
[_resourceManager] spawn {
    params ["_mgr"];
    _mgr call ["_initializeGTN", []];
};

_resourceManager
