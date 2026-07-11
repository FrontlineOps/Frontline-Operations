/*
 * Function: FLO_fnc_baseConfigureMainActions
 * Author: Frontline Operations Development Group
 * Description:
 *   Configures shared FOB/COP building actions.
 *
 * Arguments:
 * 0: Building <OBJECT>
 * 1: Base config <HASHMAP>
 *
 * Returns: None
 */
params ["_building", "_config"];

private _type = _config get "type";
private _actionPrefix = _config get "actionPrefix";
private _actions = [
    [
        "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
        { [player] call IDS_Logistics_fnc_initBuildCamera; },
        nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
    ],
    [
        "<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>STORE",
        { params ["_target"]; [_target] call FLO_fnc_storeOpenDialog; }, nil, 99999, true, true, "", "_this distance _target < 40"
    ]
];

try {
    [_building, format ["%1_MAIN", _actionPrefix], _actions] remoteExec [
        "FLO_fnc_configureObjectActionsLocal",
        0,
        format ["FLO_OBJ_ACT_%1_%2_MAIN", netId _building, _actionPrefix]
    ];
} catch {
    [_type, 1, format["Failed to configure main actions: %1", _exception]] call FLO_fnc_log;
};

[_type, 3, format["Added %1 actions to %2", count _actions, _type]] call FLO_fnc_log;
