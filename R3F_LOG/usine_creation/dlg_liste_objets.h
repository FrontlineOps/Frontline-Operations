/**
 * Interface d'affichage du contenu du v�hicule
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "dlg_constantes.h"

class R3F_LOG_dlg_liste_objets
{
	idd = R3F_LOG_IDD_dlg_liste_objets;
	name = "R3F_LOG_dlg_liste_objets";
	movingEnable = false;
	
	onUnload = "call compile preprocessFile ""R3F_LOG\usine_creation\memoriser_dlg_liste_objets.sqf"";";
	
	controlsBackground[] = {R3F_LOG_dlg_LO_titre_fond};
	objects[] = {};
	controls[] =
	{
		R3F_LOG_dlg_LO_titre,
		R3F_LOG_dlg_LO_credits_restants,
		R3F_LOG_dlg_LO_liste_categories,
		R3F_LOG_dlg_LO_liste_objets,
		R3F_LOG_dlg_LO_btn_creer,
		R3F_LOG_dlg_LO_btn_fermer,
		R3F_LOG_dlg_LO_infos_titre_fond,
		R3F_LOG_dlg_LO_infos_titre,
		R3F_LOG_dlg_LO_infos
	};
	
	// D�finition des classes de base
	class R3F_LOG_dlg_LO_texte
	{
		idc = -1;
		type = CT_STATIC;
		style = ST_LEFT;
		x = 0.0; w = 0.3;
		y = 0.0; h = 0.03;
		sizeEx = 0.023;
		colorBackground[] = {0,0,0,0};
		colorText[] = {1,1,1,1};
		font = "PuristaMedium";
		text = "";
	};
	
	class R3F_LOG_dlg_LO_btn
	{
		idc = -1;
		type = CT_SHORTCUT_BUTTON;
		style = ST_CENTER;
		
		text = "btn";
		action = "";
		
		x = 0; w = 0.195;
		y = 0; h = 0.045;
		
		font = "PuristaLight";
		size = 0.038;
		sizeEx = 0.038;
		
		animTextureNormal = "#(argb,8,8,3)color(1,1,1,1)";
		animTextureDisabled = "#(argb,8,8,3)color(1,1,1,1)";
		animTextureOver = "#(argb,8,8,3)color(1,1,1,0.5)";
		animTextureFocused = "#(argb,8,8,3)color(1,1,1,1)";
		animTexturePressed = "#(argb,8,8,3)color(1,1,1,1)";
		animTextureDefault = "#(argb,8,8,3)color(1,1,1,1)";
		textureNoShortcut = "#(argb,8,8,3)color(0,0,0,0)";
		colorBackground[] = {0,0,0,0.8};
		colorBackground2[] = {1,1,1,0.5};
		colorBackgroundFocused[] = {1,1,1,0.5};
		color[] = {1,1,1,1};
		color2[] = {1,1,1,1};
		colorText[] = {1,1,1,1};
		colorFocused[] = {1,1,1,1};
		colorDisabled[] = {1,1,1,0.25};
		period = 0.6;
		periodFocus = 0.6;
		periodOver = 0.6;
		shadow = 0;
		
		class HitZone 
		{
			left = 0.000;
			top = 0.000;
			right = 0.000;
			bottom = 0.000;
		};
		
		class ShortcutPos 
		{
			left = 0.000;
			top = 0.000;
			w = 0.023;
			h = 0.050;
		};
		
		class TextPos 
		{
			left = 0.010;
			top = 0.000;
			right = 0.000;
			bottom = 0.000;
		};
		
		soundEnter[] = {"\A3\ui_f\data\sound\RscButtonMenu\soundEnter",0.09,1};
		soundPush[] = {"\A3\ui_f\data\sound\RscButtonMenu\soundPush",0.09,1};
		soundClick[] = {"\A3\ui_f\data\sound\RscButtonMenu\soundClick",0.09,1};
		soundEscape[] = {"\A3\ui_f\data\sound\RscButtonMenu\soundEscape",0.09,1};
		
		class Attributes 
		{
			font = "PuristaLight";
			color = "#E5E5E5";
			align = "left";
			shadow = "false";
		};
		
		class AttributesImage 
		{
			font = "PuristaLight";
			color = "#E5E5E5";
			align = "left";
		};
	};
	
	class R3F_LOG_dlg_LO_liste
	{
		type = CT_LISTBOX;
		style = ST_MULTI;
		idc = -1;
		text = "";
		w = 0.275;
		h = 0.04;
		wholeHeight = 0.45;
		rowHeight = 0.035;
		font = "PuristaSemibold";
		sizeEx = 0.03;
		soundSelect[] = {"",0.1,1};
		soundExpand[] = {"",0.1,1};
		soundCollapse[] = {"",0.1,1};
		arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
		arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
		maxHistoryDelay = 1;
		autoScrollSpeed = 0;
		autoScrollDelay = 0;
		autoScrollRewind = 0;
		
		shadow = 0;
		colorShadow[] = {0,0,0,0.5};
		colorText[] = {1,1,1,1.0};
		colorDisabled[] = {1,1,1,0.25};
		colorScrollbar[] = {1,0,0,0};
		colorSelect[] = {0,0,0,1};
		colorSelect2[] = {0,0,0,1};
		colorSelectBackground[] = {0.95,0.95,0.95,1};
		colorSelectBackground2[] = {1,1,1,0.75};
		colorBackground[] = {0,0,0,0.75};
		period = 1.2;
		
		class ComboScrollBar
		{
			color[] = {1,1,1,1};
			colorActive[] = {1,1,1,1};
			colorDisabled[] = {1,1,1,0.3};
			thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
			arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
			arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
			border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
		};
		
		class ListScrollBar
		{
			color[] = {1,1,1,1};
			colorActive[] = {1,1,1,1};
			colorDisabled[] = {1,1,1,0.3};
			thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
			arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
			arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
			border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
		};
	};
	// FIN D�finition des classes de base
	
	class R3F_LOG_dlg_LO_titre_fond : R3F_LOG_dlg_LO_texte
	{
		x = safeZoneX + 0.005; w = 0.40;
		y = safeZoneY + 0.005; h = 0.07;
		colorBackground[] = {"(profileNamespace getvariable ['GUI_BCG_RGB_R',0.69])","(profileNamespace getvariable ['GUI_BCG_RGB_G',0.75])","(profileNamespace getvariable ['GUI_BCG_RGB_B',0.5])","(profileNamespace getvariable ['GUI_BCG_RGB_A',0.8])"};
	};
	
	class R3F_LOG_dlg_LO_titre : R3F_LOG_dlg_LO_texte
	{
		idc = R3F_LOG_IDC_dlg_LO_titre;
		x = safeZoneX + 0.005; w = 0.40;
		y = safeZoneY + 0.005; h = 0.04;
		sizeEx = 0.05;
		text = "";
	};
	
	class R3F_LOG_dlg_LO_credits_restants : R3F_LOG_dlg_LO_texte
	{
		idc = R3F_LOG_IDC_dlg_LO_credits_restants;
		x = safeZoneX + 0.005; w = 0.40;
		y = safeZoneY + 0.045; h = 0.03;
		sizeEx = 0.03;
		text = "";
	};
	
	class R3F_LOG_dlg_LO_liste_categories : R3F_LOG_dlg_LO_liste
	{
		idc = R3F_LOG_IDC_dlg_LO_liste_categories;
		type = CT_COMBO;
		x = safeZoneX + 0.005; w = 0.40;
		y = safeZoneY + 0.080; h = 0.045;
		onLBSelChanged = "call R3F_LOG_FNCT_usine_remplir_liste_objets;";
	};
	
	class R3F_LOG_dlg_LO_liste_objets : R3F_LOG_dlg_LO_liste
	{
		idc = R3F_LOG_IDC_dlg_LO_liste_objets;
		x = safeZoneX + 0.005; w = 0.40;
		y = safeZoneY + 0.130; h = safeZoneH - 0.185;
		onLBDblClick = "0 spawn R3F_LOG_FNCT_usine_creer_objet;";
		onLBSelChanged = "[(_this select 0) lbData (_this select 1)] call R3F_LOG_VIS_FNCT_voir_objet;";
	};
	
	class R3F_LOG_dlg_LO_btn_creer : R3F_LOG_dlg_LO_btn
	{
		idc = R3F_LOG_IDC_dlg_LO_btn_creer;
		x = safeZoneX + 0.005; y = safeZoneH + safeZoneY - 0.050;
		text = "";
		action = "0 spawn R3F_LOG_FNCT_usine_creer_objet;";
	};
	
	class R3F_LOG_dlg_LO_btn_fermer : R3F_LOG_dlg_LO_btn
	{
		idc = R3F_LOG_IDC_dlg_LO_btn_fermer;
		x = safeZoneX + 0.005 + 0.205; y = safeZoneH + safeZoneY - 0.050;
		text = "";
		action = "closeDialog 0;"; 
	};
	
	class R3F_LOG_dlg_LO_infos_titre_fond : R3F_LOG_dlg_LO_texte
	{
		x = safeZoneX + safeZoneW - 0.005 - 0.35; w = 0.35;
		y = safeZoneY + 0.005; h = 0.055;
		colorBackground[] = {"(profileNamespace getvariable ['GUI_BCG_RGB_R',0.69])","(profileNamespace getvariable ['GUI_BCG_RGB_G',0.75])","(profileNamespace getvariable ['GUI_BCG_RGB_B',0.5])","(profileNamespace getvariable ['GUI_BCG_RGB_A',0.8])"};
	};
	
	class R3F_LOG_dlg_LO_infos_titre : R3F_LOG_dlg_LO_texte
	{
		idc = R3F_LOG_IDC_dlg_LO_infos_titre;
		x = safeZoneX + safeZoneW - 0.005 - 0.35; w = 0.35;
		y = safeZoneY + 0.005; h = 0.045;
		sizeEx = 0.05;
		text = "";
	};
	
	class R3F_LOG_dlg_LO_infos : R3F_LOG_dlg_LO_texte
	{
		idc = R3F_LOG_IDC_dlg_LO_infos;
		type = CT_STRUCTURED_TEXT;
		x = safeZoneX + safeZoneW - 0.005 - 0.35; w = 0.35;
		y = safeZoneY + 0.065; h = 0.44;
		size = 0.033;
		colorBackground[] = {0,0,0,0.75};
	};
};