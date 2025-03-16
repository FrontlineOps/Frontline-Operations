/**
 * Créer un objet - appelé deuis l'interface de l'usine de création
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

if (R3F_LOG_mutex_local_verrou) then
{
	hintC STR_R3F_LOG_mutex_action_en_cours;
}
else
{
	R3F_LOG_mutex_local_verrou = true;
	
	disableSerialization; // A cause des displayCtrl
	
	#include "dlg_constantes.h"
	private ["_usine", "_classe", "_cout", "_objet", "_pos_degagee", "_action_confirmee", "_est_deplacable"];
	
	_usine = uiNamespace getVariable "R3F_LOG_dlg_LO_usine";
	
	if (lbCurSel R3F_LOG_IDC_dlg_LO_liste_objets == -1) exitWith {R3F_LOG_mutex_local_verrou = false;};
	_classe = lbData [R3F_LOG_IDC_dlg_LO_liste_objets, lbCurSel R3F_LOG_IDC_dlg_LO_liste_objets];
	
	if (_classe != "") then
	{
		_cout = [_classe] call R3F_LOG_FNCT_determiner_cout_creation;
		_est_deplacable = ([_classe] call R3F_LOG_FNCT_determiner_fonctionnalites_logistique) select R3F_LOG_IDX_can_be_moved_by_player;
		
		// L'usine a-t-elle assez de crédits ?
		if (_usine getVariable "R3F_LOG_CF_credits" == -1 || _usine getVariable "R3F_LOG_CF_credits" >= _cout) then
		{
			// Recherche d'une position dégagée. Les véhicules doivent être créé au niveau du sol sinon ils ne peuvent être utilisés.
			if (_classe isKindOf "AllVehicles") then
			{
				private ["_rayon", "_bbox", "_bbox_dim"];
				
				systemChat STR_R3F_LOG_action_creer_en_cours;
				sleep 0.5;
				
				_bbox = [_classe] call R3F_LOG_FNCT_3D_get_bounding_box_depuis_classname;
				_bbox_dim = (vectorMagnitude (_bbox select 0)) max (vectorMagnitude (_bbox select 1));
				
				// Recherche d'une position dégagée (on augmente progressivement le rayon jusqu'à trouver une position)
				for [{_rayon = 5 max (2*_bbox_dim); _pos_degagee = [];}, {count _pos_degagee == 0 && _rayon <= 30 + (8*_bbox_dim)}, {_rayon = _rayon + 10 + (2*_bbox_dim)}] do
				{
					_pos_degagee = [
						_bbox_dim,
						_usine modelToWorld [0, if (_usine isKindOf "AllVehicles") then {(boundingBoxReal _usine select 0 select 1) - 2 - 0.3*_rayon} else {0}, 0],
						_rayon,
						100 min (5 + _rayon^1.2)
					] call R3F_LOG_FNCT_3D_tirer_position_degagee_sol;
				};
			}
			else
			{
				_pos_degagee = [] call R3F_LOG_FNCT_3D_tirer_position_degagee_ciel;
			};
			
			if (count _pos_degagee > 0) then
			{
				// Si l'objet n'est ni un véhicule, ni déplaçable manuellement, on demande confirmation de création
				if (!(_classe isKindOf "AllVehicles") && !_est_deplacable) then
				{
					_action_confirmee = [STR_R3F_LOG_action_decharger_deplacable_exceptionnel, "Warning", true, true] call BIS_fnc_GUImessage;
				}
				else
				{
					_action_confirmee = true;
				};
				
				if (_action_confirmee) then
				{
					// Déduction des crédits (si limité)
					if (_usine getVariable "R3F_LOG_CF_credits" != -1) then
					{
						_usine setVariable ["R3F_LOG_CF_credits", 0 max ((_usine getVariable "R3F_LOG_CF_credits") - _cout), true];
					};
					
					_objet = _classe createVehicle _pos_degagee;
					_objet setPos _pos_degagee;
					_objet setVectorDirAndUp [[-cos getDir _usine, sin getDir _usine, 0] vectorCrossProduct surfaceNormal _pos_degagee, surfaceNormal _pos_degagee];
					_objet setVelocity [0, 0, 0];
					
					if !(isNull _objet) then
					{
						// Désactivation du bouton fermer car la création est engagée
						(findDisplay R3F_LOG_IDD_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_btn_fermer) ctrlEnable false;
						
						// Mémoriser que cet objet a été créé depuis une usine
						_objet setVariable ["R3F_LOG_CF_depuis_usine", true, true];
						
						[_objet, player] call R3F_LOG_FNCT_definir_proprietaire_verrou;
						
						sleep 0.5;
						
						// Informer tout le monde qu'il y a un nouvel objet
						R3F_LOG_PUBVAR_nouvel_objet_a_initialiser = true;
						publicVariable "R3F_LOG_PUBVAR_nouvel_objet_a_initialiser";
						
						// Prise en compte de l'objet dans l'environnement du joueur (accélérer le retour des addActions)
						_objet spawn
						{
							sleep 4;
							R3F_LOG_PUBVAR_reveler_au_joueur = _this;
							publicVariable "R3F_LOG_PUBVAR_reveler_au_joueur";
							["R3F_LOG_PUBVAR_reveler_au_joueur", R3F_LOG_PUBVAR_reveler_au_joueur] spawn R3F_LOG_FNCT_PUBVAR_reveler_au_joueur;
						};
						
						// Si l'objet créé est un drone, on y place des IA en équipage
						if (getNumber (configFile >> "CfgVehicles" >> (typeOf _objet) >> "isUav") == 1) then
						{
							createVehicleCrew _objet;
							sleep 0.5;
						};
						
						if (!(_objet isKindOf "AllVehicles") || _est_deplacable) then
						{
							R3F_LOG_mutex_local_verrou = false;
							[_objet, player, 0, true] spawn R3F_LOG_FNCT_objet_deplacer;
						}
						else
						{
							sleep 0.4; // Car la prise en compte n'est pas instantannée
							
							// Si l'objet a été créé assez loin, on indique sa position relative
							if (_objet distance _usine > 40) then
							{
								systemChat format [STR_R3F_LOG_action_creer_fait + " (%2)",
									getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName"),
									format ["%1m %2deg", round (_objet distance _usine), round ([_usine, _objet] call BIS_fnc_dirTo)]
								];
							}
							else
							{
								systemChat format [STR_R3F_LOG_action_creer_fait, getText (configFile >> "CfgVehicles" >> (typeOf _objet) >> "displayName")];
							};
							R3F_LOG_mutex_local_verrou = false;
						};
						
						closeDialog 0;
					}
					else
					{
						hintC format ["ERROR : ""%1"" is not an instanciable objet.", _classe];
						R3F_LOG_mutex_local_verrou = false;
					};
				}
				else
				{
					R3F_LOG_mutex_local_verrou = false;
				};
			}
			else
			{
				hintC format ["ERROR : no empty position found around. Creation canceled. Move out objects around the factory and try again."];
				R3F_LOG_mutex_local_verrou = false;
			};
		}
		else
		{
			hintC STR_R3F_LOG_action_creer_pas_assez_credits;
			R3F_LOG_mutex_local_verrou = false;
		};
	}
	else {R3F_LOG_mutex_local_verrou = false;};
};