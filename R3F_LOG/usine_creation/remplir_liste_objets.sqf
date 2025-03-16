/**
 * Enregistre les valeurs des champs avant fermeture de la boîte de dialogue de l'usine de création.
 * ouvrir_usine.sqf s'en servira pour la préremplir à l'ouverture
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

disableSerialization; // A cause des displayCtrl

private ["_usine", "_dlg_liste_objets", "_ctrl_liste_objets", "_sel_categorie", "_sel_objet"];

#include "dlg_constantes.h"

_usine = uiNamespace getVariable "R3F_LOG_dlg_LO_usine";

_dlg_liste_objets = findDisplay R3F_LOG_IDD_dlg_liste_objets;

_ctrl_liste_objets = _dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_liste_objets;

_sel_categorie = lbCurSel (_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_liste_categories);
_sel_objet = 0 max (_usine getVariable "R3F_LOG_CF_mem_idx_objet");
_usine setVariable ["R3F_LOG_CF_mem_idx_objet", 0];

lbClear _ctrl_liste_objets;

if (count (_usine getVariable "R3F_LOG_CF_cfgVehicles_par_categories") > 0) then
{
	// Insertion de chaque type d'objets disponibles dans la liste
	{
		private ["_classe", "_config", "_nom", "_icone", "_cout", "_tab_icone", "_index"];
		
		_classe = _x;
		_config = configFile >> "CfgVehicles" >> _classe;
		_nom = getText (_config >> "displayName");
		_icone = getText (_config >> "icon");
		_cout = [_classe] call R3F_LOG_FNCT_determiner_cout_creation;
		
		// Icône par défaut
		if (_icone == "") then
		{
			_icone = "\A3\ui_f\data\map\VehicleIcons\iconObject_ca.paa";
		};
		
		// Si le chemin commence par A3\ ou a3\, on rajoute un \ au début
		_tab_icone = toArray toLower _icone;
		if (count _tab_icone >= 3 &&
			{
				_tab_icone select 0 == (toArray "a" select 0) &&
				_tab_icone select 1 == (toArray "3" select 0) &&
				_tab_icone select 2 == (toArray "\" select 0)
			}) then
		{
			_icone = "\" + _icone;
		};
		
		// Si icône par défaut, on rajoute le chemin de base par défaut
		_tab_icone = toArray _icone;
		if (_tab_icone select 0 != (toArray "\" select 0)) then
		{
			_icone = format ["\A3\ui_f\data\map\VehicleIcons\%1_ca.paa", _icone];
		};
		
		// Si pas d'extension de fichier, on rajoute ".paa"
		_tab_icone = toArray _icone;
		if (count _tab_icone >= 4 && {_tab_icone select (count _tab_icone - 4) != (toArray "." select 0)}) then
		{
			_icone = _icone + ".paa";
		};
		
		_index = _ctrl_liste_objets lbAdd format ["%1 (%2 cred.)", _nom, [_cout] call R3F_LOG_FNCT_formater_nombre_entier_milliers];
		_ctrl_liste_objets lbSetPicture [_index, _icone];
		_ctrl_liste_objets lbSetData [_index, _classe];
	} forEach (_usine getVariable "R3F_LOG_CF_cfgVehicles_par_categories" select _sel_categorie);
	
	// Ajout d'une ligne vide car l'affichage des listes de BIS est bugué (dernier élément masqué).....
	_ctrl_liste_objets lbSetData [_ctrl_liste_objets lbAdd "", ""];
	
	// Sélectionner l'objet mémoriser en le plaçant visuellement au centre de la liste
	_ctrl_liste_objets lbSetCurSel (lbSize _ctrl_liste_objets - 1);
	_ctrl_liste_objets lbSetCurSel (_sel_objet - 8 max 0);
	_ctrl_liste_objets lbSetCurSel _sel_objet;
};