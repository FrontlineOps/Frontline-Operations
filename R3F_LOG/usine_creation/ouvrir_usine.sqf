/**
 * Ouvre la boîte de dialogue du contenu de l'usine
 * 
 * @param 0 l'usine qu'il faut ouvrir
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "dlg_constantes.h"

disableSerialization; // A cause des displayCtrl

private ["_usine", "_credits_usine", "_dlg_liste_objets", "_ctrl_liste_categories", "_sel_categorie"];

R3F_LOG_objet_selectionne = objNull;

_usine = _this select 0;
uiNamespace setVariable ["R3F_LOG_dlg_LO_usine", _usine];

call R3F_LOG_VIS_FNCT_demarrer_visualisation;

// Pré-calculer une fois pour toutes les usines la liste des objets du CfgVehicles classés par catégorie
if (isNil {_usine getVariable "R3F_LOG_CF_cfgVehicles_par_categories"}) then
{
	private ["_retour_liste_cfgVehicles_par_categories"];
	
	_retour_liste_cfgVehicles_par_categories = [_usine] call R3F_LOG_FNCT_recuperer_liste_cfgVehicles_par_categories;
	
	_usine setVariable ["R3F_LOG_CF_cfgVehicles_categories", + (_retour_liste_cfgVehicles_par_categories select 0)];
	_usine setVariable ["R3F_LOG_CF_cfgVehicles_par_categories", + (_retour_liste_cfgVehicles_par_categories select 1)];
};

createDialog "R3F_LOG_dlg_liste_objets";
_dlg_liste_objets = findDisplay R3F_LOG_IDD_dlg_liste_objets;

/**** DEBUT des traductions des labels ****/
(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_titre) ctrlSetText STR_R3F_LOG_dlg_LO_titre;
(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_btn_creer) ctrlSetText STR_R3F_LOG_dlg_LO_btn_creer;
(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_btn_fermer) ctrlSetText STR_R3F_LOG_dlg_LO_btn_fermer;
(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_infos_titre) ctrlSetText STR_R3F_LOG_nom_fonctionnalite_proprietes;
/**** FIN des traductions des labels ****/

_ctrl_liste_categories = _dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_liste_categories;
_sel_categorie = 0 max (_usine getVariable "R3F_LOG_CF_mem_idx_categorie");

// Insertion de chaque catégories disponibles dans la liste
{
	private ["_categorie", "_config", "_nom"];
	
	_categorie = _x;
	_config = configFile >> "CfgVehicleClasses" >> _categorie;
	_nom = getText (_config >> "displayName");
	
	_index = _ctrl_liste_categories lbAdd format ["%1", _nom];
	_ctrl_liste_categories lbSetData [_index, _categorie];
} forEach (_usine getVariable "R3F_LOG_CF_cfgVehicles_categories");

_ctrl_liste_categories lbSetCurSel _sel_categorie;

while {!isNull _dlg_liste_objets} do
{
	_credits_usine = -1;
	
	// Activer le bouton de création que s'il y a assez de crédits
	(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_btn_creer) ctrlEnable (_credits_usine != 0);
	
	if (_credits_usine == -1) then
	{
		(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_credits_restants) ctrlSetText (format [STR_R3F_LOG_dlg_LO_credits_restants, "unlimited"]);
	}
	else
	{
		(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_credits_restants) ctrlSetText (format [STR_R3F_LOG_dlg_LO_credits_restants, _credits_usine]);
	};
	
	// Afficher les infos de l'objet
	if (lbCurSel R3F_LOG_IDC_dlg_LO_liste_objets != -1) then
	{
		(_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_infos) ctrlSetStructuredText ([lbData [R3F_LOG_IDC_dlg_LO_liste_objets, lbCurSel R3F_LOG_IDC_dlg_LO_liste_objets]] call R3F_LOG_FNCT_formater_fonctionnalites_logistique);
	};
	
	// Fermer la boîte de dialogue si l'usine n'est plus accessible
	if (!alive _usine || (_usine getVariable "R3F_LOG_CF_disabled")) then
	{
		closeDialog 0;
	};
	
	sleep 0.15;
};

call R3F_LOG_VIS_FNCT_terminer_visualisation;