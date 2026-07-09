/*
 * Scripts/defines.hpp - BACKWARD COMPATIBILITY WRAPPER
 * Author: Frontline Operations
 *
 * Description:
 * This file now includes the unified UI system from UI/defines.hpp.
 * Legacy classes are preserved below for backward compatibility with
 * existing dialogs. New dialogs should use FLO_* prefixed classes.
 *
 * Migration:
 * - New dialogs should #include "UI\defines.hpp" directly
 * - Use FLO_RscText, FLO_RscButton, etc. for new development
 *
 * This file will be deprecated in a future version.
 */

// ============================================================================
// UNIFIED UI SYSTEM
// ============================================================================

#include "..\UI\defines.hpp"

// ============================================================================
// LEGACY COMPATIBILITY - Classes below preserved for existing dialogs
// ============================================================================

// Note: Base classes (RscText, RscButton, RscCombo, RscListBox, RscEdit,
// RscStructuredText, RscPicture, RscFrame, RscSlider, RscCheckbox, RscProgress,
// RscTree, RscControlsGroup, RscMap) are now defined in UI/defines.hpp.
// The unified versions use FLO_COLOR_* constants and improved defaults.
// Legacy dialogs will still work as the class names are preserved.

// ============================================================================
// LEGACY-SPECIFIC CLASSES (not in unified system)
// ============================================================================

// Legacy XSlider class (different naming from RscXSlider)
class CT_XSLIDER
{
	type = 43;
	idc = -1;
	style = SL_HORZ;
	arrowEmpty = "\A3\ui_f\data\gui\cfg\slider\arrowEmpty_ca.paa";
	arrowFull = "\A3\ui_f\data\gui\cfg\slider\arrowFull_ca.paa";
	border = "\A3\ui_f\data\gui\cfg\slider\border_ca.paa";
	thumb = "\A3\ui_f\data\gui\cfg\slider\thumb_ca.paa";
	color[] = {0.2, 0.2, 0.2, 1};
	coloractive[] = {1, 0.77, 0.5, 1};
};
class RscShortcutButton
{
	type = 16;
	x = 0.1;
	y = 0.1;
	class HitZone
	{
		left = 0.004;
		top = 0.029;
		right = 0.004;
		bottom = 0.029;
	};
	class ShortcutPos
	{
		left = 0.0145;
		top = 0.026;
		w = 0.0392157;
		h = 0.0522876;
	};
	class TextPos
	{
		left = 0.05;
		top = 0.034;
		right = 0.005;
		bottom = 0.005;
	};
	shortcuts[] = {};
	textureNoShortcut = "#(argb,8,8,3)color(0,0,0,0)";
	color[] = {0.8784,0.8471,0.651,1};
	color2[] = {0.95,0.95,0.95,1};
	colorDisabled[] = {1,1,1,0.25};
	colorBackground[] = {1,1,1,1};
	colorBackground2[] = {1,1,1,0.4};
	class Attributes
	{
		font = "RobotoCondensed";
		color = "#E5E5E5";
		align = "left";
		shadow = "true";
	};
	idc = -1;
	style = 0;
	default = 0;
	shadow = 0;
	w = 0.183825;
	h = 0.104575;
	periodFocus = 1.2;
	periodOver = 0.8;
	animTextureNormal = "\ca\ui\data\ui_button_normal_ca.paa";
	animTextureDisabled = "\ca\ui\data\ui_button_disabled_ca.paa";
	animTextureOver = "\ca\ui\data\ui_button_over_ca.paa";
	animTextureFocused = "\ca\ui\data\ui_button_focus_ca.paa";
	animTexturePressed = "\ca\ui\data\ui_button_down_ca.paa";
	animTextureDefault = "\ca\ui\data\ui_button_default_ca.paa";
	period = 0.4;
	font = "RobotoCondensed";
	size = 0.03921;
	sizeEx = 0.03921;
	text = "";
	soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter",0.09,1};
	soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush",0,0};
	soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick",0.07,1};
	soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape",0.09,1};
	action = "";
	class AttributesImage
	{
		font = "RobotoCondensed";
		color = "#E5E5E5";
		align = "left";
	};
};
class RscShortcutButtonMain
{
	idc = -1;
	style = 0;
	default = 0;
	w = 0.313726;
	h = 0.104575;
	color[] = {0.8784,0.8471,0.651,1};
	colorDisabled[] = {1,1,1,0.25};
	class HitZone
	{
		left = 0;
		top = 0;
		right = 0;
		bottom = 0;
	};
	class ShortcutPos
	{
		left = 0.0204;
		top = 0.026;
		w = 0.0392157;
		h = 0.0522876;
	};
	class TextPos
	{
		left = 0.08;
		top = 0.034;
		right = 0.005;
		bottom = 0.005;
	};
	animTextureNormal = "\ca\ui\data\ui_button_main_normal_ca.paa";
	animTextureDisabled = "\ca\ui\data\ui_button_main_disabled_ca.paa";
	animTextureOver = "\ca\ui\data\ui_button_main_over_ca.paa";
	animTextureFocused = "\ca\ui\data\ui_button_main_focus_ca.paa";
	animTexturePressed = "\ca\ui\data\ui_button_main_down_ca.paa";
	animTextureDefault = "\ca\ui\data\ui_button_main_normal_ca.paa";
	period = 0.5;
	font = "RobotoCondensed";
	size = 0.03921;
	sizeEx = 0.03921;
	text = "";
	soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter",0.09,1};
	soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush",0,0};
	soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick",0.07,1};
	soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape",0.09,1};
	action = "";
	class Attributes
	{
		font = "RobotoCondensed";
		color = "#E5E5E5";
		align = "left";
		shadow = "false";
	};
	class AttributesImage
	{
		font = "RobotoCondensed";
		color = "#E5E5E5";
		align = "false";
	};
};

// Note: RscFrame and RscSlider are now defined in UI/defines.hpp

/*
$[
	1.03,
	[["safezoneX","safezoneY","safezoneW","safezoneH"],"safezoneW / 32","safezoneH / 20"],
	[1000,"MyBackground",[1,"",["0.3125 * safezoneW + safezoneX","0.35 * safezoneH + safezoneY","0.375 * safezoneW","0.3 * safezoneH"],[-1,-1,-1,-1],[0,0,0,0.5],[-1,-1,-1,-1],""],[]],
	[1001,"MyHeader",[1,"Hello World",["0.3125 * safezoneW + safezoneX","0.35 * safezoneH + safezoneY","0.375 * safezoneW","0.05 * safezoneH"],[-1,-1,-1,-1],[0,0,0,0.5],[-1,-1,-1,-1],""],["style = ST_CENTER;"]],
	[1400,"MyEditbox",[1,"",["0.328125 * safezoneW + safezoneX","0.425 * safezoneH + safezoneY","0.34375 * safezoneW","0.15 * safezoneH"],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],""],["idc = 1234;"]],
	[1700,"MyButtonOK",[1,"Ok",["0.53125 * safezoneW + safezoneX","0.575 * safezoneH + safezoneY","0.140625 * safezoneW","0.1 * safezoneH"],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],""],["onButtonClick = |hint ctrltext ((ctrlParent (_this select 0)) displayCtrl 1234);|;"]],
	[1701,"MyButtonBack",[1,"Cancel",["0.328125 * safezoneW + safezoneX","0.575 * safezoneH + safezoneY","0.140625 * safezoneW","0.1 * safezoneH"],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],""],["onButtonClick = |((ctrlParent (_this select 0)) closeDisplay 3000);|;"]]
]
*/


class RscDisplayTest
{
	idd = 3000;
	movingenable = 0;

	class Controls
	{
		class MyBackground: RscText
		{
			idc = 1000;
			x = "0.3125 * safezoneW + safezoneX";
			y = "0.35 * safezoneH + safezoneY";
			w = "0.375 * safezoneW";
			h = "0.3 * safezoneH";
			colorBackground[] = {0,0,0,0.5};
		};
		class MyHeader: RscText
		{
			style = ST_CENTER;

			idc = 1001;
			text = "Hello World";
			x = "0.3125 * safezoneW + safezoneX";
			y = "0.35 * safezoneH + safezoneY";
			w = "0.375 * safezoneW";
			h = "0.05 * safezoneH";
			colorBackground[] = {0,0,0,0.5};
		};
		class MyEditbox: RscEdit
		{
			idc = 1234;

			x = "0.328125 * safezoneW + safezoneX";
			y = "0.425 * safezoneH + safezoneY";
			w = "0.34375 * safezoneW";
			h = "0.15 * safezoneH";
		};
		class MyButtonOK: RscShortcutButton
		{
			onButtonClick = "hint ctrltext ((ctrlParent (_this select 0)) displayCtrl 1234);";

			idc = 1700;
			text = "Ok";
			x = "0.53125 * safezoneW + safezoneX";
			y = "0.575 * safezoneH + safezoneY";
			w = "0.140625 * safezoneW";
			h = "0.1 * safezoneH";
		};
		class MyButtonBack: RscShortcutButton
		{
			onButtonClick = "((ctrlParent (_this select 0)) closeDisplay 3000);";

			idc = 1701;
			text = "Cancel";
			x = "0.328125 * safezoneW + safezoneX";
			y = "0.575 * safezoneH + safezoneY";
			w = "0.140625 * safezoneW";
			h = "0.1 * safezoneH";
		};
	};
};
/////////////////////////////////////////////////////
class IGUIBack
{
	type = 0;
	idc = 124;
	style = 128;
	text = "";
	colorText[] =
	{
		0,
		0,
		0,
		0
	};
	font = "RobotoCondensed";
	sizeEx = 0;
	shadow = 0;
	x = 0.1;
	y = 0.1;
	w = 0.1;
	h = 0.1;
	colorbackground[] =
	{
		"(profileNamespace getvariable ['IGUI_BCG_RGB_R',0])",
		"(profileNamespace getvariable ['IGUI_BCG_RGB_G',1])",
		"(profileNamespace getvariable ['IGUI_BCG_RGB_B',1])",
		"(profileNamespace getvariable ['IGUI_BCG_RGB_A',0.8])"
	};
};

// Note: RscCheckbox is now defined in UI/defines.hpp

// Legacy menu button classes (shortcut button variant)
class RscButtonMenu
{
	idc = -1;
	type = 16;
	style = "0x02 + 0xC0";
	default = 0;
	shadow = 0;
	x = 0;
	y = 0;
	w = 0.095589;
	h = 0.039216;
	animTextureNormal = "#(argb,8,8,3)color(1,1,1,1)";
	animTextureDisabled = "#(argb,8,8,3)color(1,1,1,1)";
	animTextureOver = "#(argb,8,8,3)color(1,1,1,0.5)";
	animTextureFocused = "#(argb,8,8,3)color(1,1,1,1)";
	animTexturePressed = "#(argb,8,8,3)color(1,1,1,1)";
	animTextureDefault = "#(argb,8,8,3)color(1,1,1,1)";
	colorBackground[] =
	{
		0,
		0,
		0,
		0.8
	};
	colorBackground2[] =
	{
		1,
		1,
		1,
		0.5
	};
	color[] =
	{
		1,
		1,
		1,
		1
	};
	color2[] =
	{
		1,
		1,
		1,
		1
	};
	colorText[] =
	{
		1,
		1,
		1,
		1
	};
	colorDisabled[] =
	{
		1,
		1,
		1,
		0.25
	};
	period = 1.2;
	periodFocus = 1.2;
	periodOver = 1.2;
	size = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
	sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
	class TextPos
	{
		left = "0.25 * (((safezoneW / safezoneH) min 1.2) / 40)";
		top = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) - (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)) / 2";
		right = 0.005;
		bottom = 0;
	};
	class Attributes
	{
		font = "RobotoCondensedLight";
		color = "#E5E5E5";
		align = "left";
		shadow = "false";
	};
	class ShortcutPos
	{
		left = "(6.25 * (((safezoneW / safezoneH) min 1.2) / 40)) - 0.0225 - 0.005";
		top = 0.005;
		w = 0.0225;
		h = 0.03;
	};
	soundEnter[] =
	{
		"\A3\ui_f\data\sound\RscButtonMenu\soundEnter",
		0.09,
		1
	};
	soundPush[] =
	{
		"\A3\ui_f\data\sound\RscButtonMenu\soundPush",
		0.09,
		1
	};
	soundClick[] =
	{
		"\A3\ui_f\data\sound\RscButtonMenu\soundClick",
		0.09,
		1
	};
	soundEscape[] =
	{
		"\A3\ui_f\data\sound\RscButtonMenu\soundEscape",
		0.09,
		1
	};
};
class RscButtonMenuOK
{
	idc = 1;
	shortcuts[] =
	{
		"0x00050000 + 0",
		28,
		57,
		156
	};
	default = 1;
	text = "OK";
	soundPush[] =
	{
		"\A3\ui_f\data\sound\RscButtonMenuOK\soundPush",
		0.09,
		1
	};
};
class RscButtonMenuCancel
{
	idc = 2;
	shortcuts[] =
	{
		"0x00050000 + 1"
	};
	text = "Cancel";
};

// Note: RscControlsGroup is now defined in UI/defines.hpp
