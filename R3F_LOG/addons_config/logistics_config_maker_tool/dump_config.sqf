/**
 * Dump the effective logistics configuration to the RPT file.
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
private ["_idx"];

systemChat "DUMPING CONFIG...";
diag_log text "============= BEGIN OF LOGISTICS CONFIG DUMP =============";

diag_log text "R3F_LOG_CFG_can_tow = R3F_LOG_CFG_can_tow +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_tow}, {_idx = _idx+1}] do
{
	diag_log text format ["	""%1""%2", R3F_LOG_CFG_can_tow select _idx, if (_idx < count R3F_LOG_CFG_can_tow - 1) then {","} else {""}];
};
diag_log text "];";
diag_log text "";

diag_log text "R3F_LOG_CFG_can_be_towed = R3F_LOG_CFG_can_be_towed +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_be_towed}, {_idx = _idx+1}] do
{
	diag_log text format ["	""%1""%2", R3F_LOG_CFG_can_be_towed select _idx, if (_idx < count R3F_LOG_CFG_can_be_towed - 1) then {","} else {""}];
};
diag_log text "];";
diag_log text "";

diag_log text "R3F_LOG_CFG_can_lift = R3F_LOG_CFG_can_lift +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_lift}, {_idx = _idx+1}] do
{
	diag_log text format ["	""%1""%2", R3F_LOG_CFG_can_lift select _idx, if (_idx < count R3F_LOG_CFG_can_lift - 1) then {","} else {""}];
};
diag_log text "];";
diag_log text "";

diag_log text "R3F_LOG_CFG_can_be_lifted = R3F_LOG_CFG_can_be_lifted +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_be_lifted}, {_idx = _idx+1}] do
{
	diag_log text format ["	""%1""%2", R3F_LOG_CFG_can_be_lifted select _idx, if (_idx < count R3F_LOG_CFG_can_be_lifted - 1) then {","} else {""}];
};
diag_log text "];";
diag_log text "";

diag_log text "R3F_LOG_CFG_can_transport_cargo = R3F_LOG_CFG_can_transport_cargo +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_transport_cargo}, {_idx = _idx+1}] do
{
	diag_log text format ["	[""%1"", %2]%3", R3F_LOG_CFG_can_transport_cargo select _idx select 0, R3F_LOG_CFG_can_transport_cargo select _idx select 1, if (_idx < count R3F_LOG_CFG_can_transport_cargo - 1) then {","} else {""}];
};
diag_log text "];";
diag_log text "";

diag_log text "R3F_LOG_CFG_can_be_transported_cargo = R3F_LOG_CFG_can_be_transported_cargo +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_be_transported_cargo}, {_idx = _idx+1}] do
{
	diag_log text format ["	[""%1"", %2]%3", R3F_LOG_CFG_can_be_transported_cargo select _idx select 0, R3F_LOG_CFG_can_be_transported_cargo select _idx select 1, if (_idx < count R3F_LOG_CFG_can_be_transported_cargo - 1) then {","} else {""}];
};
diag_log text "];";
diag_log text "";

diag_log text "R3F_LOG_CFG_can_be_moved_by_player = R3F_LOG_CFG_can_be_moved_by_player +";
diag_log text "[";
for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_be_moved_by_player}, {_idx = _idx+1}] do
{
	diag_log text format ["	""%1""%2", R3F_LOG_CFG_can_be_moved_by_player select _idx, if (_idx < count R3F_LOG_CFG_can_be_moved_by_player - 1) then {","} else {""}];
};
diag_log text "];";

diag_log text "============== END OF LOGISTICS CONFIG DUMP ==============";
systemChat "CONFIG DUMPED TO RPT !";