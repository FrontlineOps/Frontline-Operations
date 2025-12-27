/*
 * FLO Unified UI Defines
 * Author: Frontline Operations
 * 
 * Description:
 * Unified base control class definitions for all FLO dialogs.
 * This file consolidates and replaces duplicate definitions from
 * Scripts/defines.hpp and IDS_Logistics/dialogs/BaseControls.hpp
 * 
 * Usage:
 * #include "UI\defines.hpp"
 */

// ============================================================================
// ARMA SYSTEM INCLUDES
// ============================================================================

// Eden Editor macros (background colour, pixel grid)
#include "\a3\3DEN\UI\macros.inc"

// Common grid definitions
#include "\a3\ui_f\hpp\definecommongrids.inc"

// DIK Key Codes
#include "\a3\ui_f\hpp\definedikcodes.inc"

// Eden Editor IDDs, IDCs, control types, styles, macros
#include "\a3\3den\ui\resincl.inc"

// ============================================================================
// CONTROL TYPES
// ============================================================================

#define CT_STATIC           0
#define CT_BUTTON           1
#define CT_EDIT             2
#define CT_SLIDER           3
#define CT_COMBO            4
#define CT_LISTBOX          5
#define CT_TOOLBOX          6
#define CT_CHECKBOXES       7
#define CT_PROGRESS         8
#define CT_HTML             9
#define CT_STATIC_SKEW      10
#define CT_ACTIVETEXT       11
#define CT_TREE             12
#define CT_STRUCTURED_TEXT  13
#define CT_CONTEXT_MENU     14
#define CT_CONTROLS_GROUP   15
#define CT_SHORTCUTBUTTON   16
#define CT_HITZONES         17
#define CT_XKEYDESC         40
#define CT_XBUTTON          41
#define CT_XLISTBOX         42
#define CT_XSLIDER          43
#define CT_XCOMBO           44
#define CT_ANIMATED_TEXTURE 45
#define CT_CHECKBOX         77
#define CT_OBJECT           80
#define CT_OBJECT_ZOOM      81
#define CT_OBJECT_CONTAINER 82
#define CT_OBJECT_CONT_ANIM 83
#define CT_LINEBREAK        98
#define CT_USER             99
#define CT_MAP              100
#define CT_MAP_MAIN         101
#define CT_LISTNBOX         102
#define CT_ITEMSLOT         103

// ============================================================================
// STYLE CONSTANTS
// ============================================================================

// Position styles
#define ST_POS              0x0F
#define ST_HPOS             0x03
#define ST_VPOS             0x0C
#define ST_LEFT             0x00
#define ST_RIGHT            0x01
#define ST_CENTER           0x02
#define ST_DOWN             0x04
#define ST_UP               0x08
#define ST_VCENTER          0x0C

// Type styles
#define ST_TYPE             0xF0
#define ST_SINGLE           0x00
#define ST_MULTI            0x10
#define ST_TITLE_BAR        0x20
#define ST_PICTURE          0x30
#define ST_FRAME            0x40
#define ST_BACKGROUND       0x50
#define ST_GROUP_BOX        0x60
#define ST_GROUP_BOX2       0x70
#define ST_HUD_BACKGROUND   0x80
#define ST_TILE_PICTURE     0x90
#define ST_WITH_RECT        0xA0
#define ST_LINE             0xB0
#define ST_UPPERCASE        0xC0
#define ST_LOWERCASE        0xD0

// Additional styles
#define ST_SHADOW           0x100
#define ST_NO_RECT          0x200
#define ST_KEEP_ASPECT_RATIO 0x800

// Combined styles
#define ST_TITLE            (ST_TITLE_BAR + ST_CENTER)

// Slider styles
#define SL_DIR              0x400
#define SL_VERT             0
#define SL_HORZ             0x400
#define SL_TEXTURES         0x10

// Progress bar styles
#define ST_VERTICAL         0x01
#define ST_HORIZONTAL       0

// Listbox styles
#define LB_TEXTURES         0x10
#define LB_MULTI            0x20

// Tree styles
#define TR_SHOWROOT         1
#define TR_AUTOCOLLAPSE     2

// MessageBox styles
#define MB_BUTTON_OK        1
#define MB_BUTTON_CANCEL    2
#define MB_BUTTON_USER      4

// ============================================================================
// GRID CALCULATIONS (Responsive)
// ============================================================================

#define GUI_GRID_WAbs       ((safezoneW / safezoneH) min 1.2)
#define GUI_GRID_HAbs       (GUI_GRID_WAbs / 1.2)
#define GUI_GRID_W          (GUI_GRID_WAbs / 40)
#define GUI_GRID_H          (GUI_GRID_HAbs / 25)
#define GUI_GRID_X          (safezoneX)
#define GUI_GRID_Y          (safezoneY + safezoneH - GUI_GRID_HAbs)

// Text sizes based on grid
#define GUI_TEXT_SIZE_SMALL  (GUI_GRID_H * 0.8)
#define GUI_TEXT_SIZE_MEDIUM (GUI_GRID_H * 1.0)
#define GUI_TEXT_SIZE_LARGE  (GUI_GRID_H * 1.2)

// Pixel grid (for precise positioning)
#define pixelScale          0.50
#define GRID_W              (pixelW * pixelGrid * pixelScale)
#define GRID_H              (pixelH * pixelGrid * pixelScale)

// ============================================================================
// INCLUDE FLO CONSTANTS
// ============================================================================

#include "constants.hpp"

// ============================================================================
// SCROLLBAR BASE CLASS
// ============================================================================

class FLO_ScrollBar
{
	color[] = {1, 1, 1, 0.6};
	colorActive[] = {1, 1, 1, 1};
	colorDisabled[] = {1, 1, 1, 0.3};
	thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
	arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
	arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
	border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
	shadow = 0;
	scrollSpeed = 0.06;
	width = 0;
	height = 0;
	autoScrollEnabled = 0;
	autoScrollSpeed = -1;
	autoScrollDelay = 5;
	autoScrollRewind = 0;
};

// ============================================================================
// BASE CONTROL CLASSES
// ============================================================================

class RscText
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_STATIC;
	idc = -1;
	style = ST_LEFT;
	colorBackground[] = FLO_COLOR_TRANSPARENT;
	colorText[] = FLO_COLOR_TEXT;
	text = "";
	fixedWidth = 0;
	x = 0;
	y = 0;
	w = 0.3;
	h = 0.037;
	shadow = 1;
	colorShadow[] = {0, 0, 0, 0.5};
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	linespacing = 1;
	tooltipColorText[] = FLO_COLOR_TOOLTIP_TEXT;
	tooltipColorBox[] = FLO_COLOR_TOOLTIP_BOX;
	tooltipColorShade[] = FLO_COLOR_TOOLTIP_BG;
};

class RscStructuredText
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_STRUCTURED_TEXT;
	idc = -1;
	style = ST_LEFT;
	colorText[] = FLO_COLOR_TEXT;
	x = 0;
	y = 0;
	w = 0.1;
	h = 0.035;
	text = "";
	size = GUI_TEXT_SIZE_MEDIUM;
	shadow = 1;
	class Attributes
	{
		font = "RobotoCondensed";
		color = "#FFFFFF";
		align = "left";
		shadow = 1;
	};
};

class RscPicture
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_STATIC;
	idc = -1;
	style = ST_PICTURE;
	colorBackground[] = FLO_COLOR_TRANSPARENT;
	colorText[] = FLO_COLOR_TEXT;
	font = "TahomaB";
	sizeEx = 0;
	lineSpacing = 0;
	text = "";
	fixedWidth = 0;
	shadow = 0;
	x = 0;
	y = 0;
	w = 0.2;
	h = 0.15;
	tooltipColorText[] = FLO_COLOR_TOOLTIP_TEXT;
	tooltipColorBox[] = FLO_COLOR_TOOLTIP_BOX;
	tooltipColorShade[] = FLO_COLOR_TOOLTIP_BG;
};

class RscPictureKeepAspect: RscPicture
{
	style = ST_PICTURE + ST_KEEP_ASPECT_RATIO;
};

class RscFrame
{
	type = CT_STATIC;
	idc = -1;
	deletable = 0;
	style = ST_FRAME;
	shadow = 2;
	colorBackground[] = FLO_COLOR_TRANSPARENT;
	colorText[] = FLO_COLOR_TEXT;
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	text = "";
	x = 0;
	y = 0;
	w = 0.3;
	h = 0.3;
};

class RscLine: RscText
{
	idc = -1;
	style = ST_LINE;
	x = 0.17;
	y = 0.48;
	w = 0.66;
	h = 0;
	text = "";
	colorBackground[] = FLO_COLOR_TRANSPARENT;
	colorText[] = FLO_COLOR_BORDER;
};

class RscProgress
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_PROGRESS;
	style = ST_HORIZONTAL;
	colorFrame[] = FLO_COLOR_BORDER;
	colorBar[] = FLO_COLOR_PRIMARY;
	x = 0.344;
	y = 0.619;
	w = 0.313726;
	h = 0.0261438;
	shadow = 2;
	texture = "#(argb,8,8,3)color(1,1,1,1)";
};

class RscButton
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_BUTTON;
	idc = -1;
	style = ST_CENTER;
	text = "";
	colorText[] = FLO_COLOR_TEXT;
	colorDisabled[] = FLO_COLOR_TEXT_DISABLED;
	colorBackground[] = FLO_COLOR_BUTTON_BG;
	colorBackgroundDisabled[] = FLO_COLOR_BUTTON_DISABLED;
	colorBackgroundActive[] = FLO_COLOR_BUTTON_HOVER;
	colorFocused[] = FLO_COLOR_BUTTON_HOVER;
	colorShadow[] = {0, 0, 0, 0};
	colorBorder[] = {0, 0, 0, 0};
	soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter", 0.09, 1};
	soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush", 0.09, 1};
	soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick", 0.09, 1};
	soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape", 0.09, 1};
	x = 0;
	y = 0;
	w = 0.095589;
	h = 0.039216;
	shadow = 2;
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	url = "";
	offsetX = 0;
	offsetY = 0;
	offsetPressedX = 0;
	offsetPressedY = 0;
	borderSize = 0;
};

class RscEdit
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_EDIT;
	idc = -1;
	style = ST_LEFT;
	colorBackground[] = FLO_COLOR_INPUT_BG;
	colorText[] = FLO_COLOR_TEXT;
	colorDisabled[] = FLO_COLOR_TEXT_DISABLED;
	colorSelection[] = FLO_COLOR_SELECT_BG;
	autocomplete = "";
	text = "";
	size = 0.2;
	font = "RobotoCondensed";
	shadow = 2;
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	canModify = 1;
	x = 0;
	y = 0;
	w = 0.2;
	h = 0.04;
	tooltipColorText[] = FLO_COLOR_TOOLTIP_TEXT;
	tooltipColorBox[] = FLO_COLOR_TOOLTIP_BOX;
	tooltipColorShade[] = FLO_COLOR_TOOLTIP_BG;
};

class RscCombo
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_COMBO;
	idc = -1;
	style = 0;
	colorSelect[] = FLO_COLOR_SELECT_TEXT;
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_SURFACE;
	colorScrollbar[] = FLO_COLOR_SCROLLBAR;
	colorDisabled[] = FLO_COLOR_TEXT_DISABLED;
	colorPicture[] = FLO_COLOR_TEXT;
	colorPictureSelected[] = FLO_COLOR_TEXT;
	colorPictureDisabled[] = FLO_COLOR_TEXT_DISABLED;
	colorPictureRight[] = FLO_COLOR_TEXT;
	colorPictureRightSelected[] = FLO_COLOR_TEXT;
	colorPictureRightDisabled[] = FLO_COLOR_TEXT_DISABLED;
	colorTextRight[] = FLO_COLOR_TEXT;
	colorSelectRight[] = FLO_COLOR_SELECT_TEXT;
	colorSelect2Right[] = FLO_COLOR_SELECT_TEXT;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	colorSelectBackground2[] = FLO_COLOR_PRIMARY;
	colorActive[] = FLO_COLOR_PRIMARY;
	tooltipColorText[] = FLO_COLOR_TOOLTIP_TEXT;
	tooltipColorBox[] = FLO_COLOR_TOOLTIP_BOX;
	tooltipColorShade[] = FLO_COLOR_TOOLTIP_BG;
	soundSelect[] = {"\A3\ui_f\data\sound\RscCombo\soundSelect", 0.1, 1};
	soundExpand[] = {"\A3\ui_f\data\sound\RscCombo\soundExpand", 0.1, 1};
	soundCollapse[] = {"\A3\ui_f\data\sound\RscCombo\soundCollapse", 0.1, 1};
	maxHistoryDelay = 1;
	x = 0;
	y = 0;
	w = 0.12;
	h = 0.035;
	shadow = 0;
	arrowEmpty = "\A3\ui_f\data\GUI\RscCommon\rsccombo\arrow_combo_ca.paa";
	arrowFull = "\A3\ui_f\data\GUI\RscCommon\rsccombo\arrow_combo_active_ca.paa";
	wholeHeight = 0.45;
	color[] = FLO_COLOR_SCROLLBAR;
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	class ComboScrollBar: FLO_ScrollBar {};
};

class RscListBox
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_LISTBOX;
	idc = -1;
	style = LB_TEXTURES;
	colorText[] = FLO_COLOR_TEXT;
	colorDisabled[] = FLO_COLOR_TEXT_DISABLED;
	colorBackground[] = FLO_COLOR_SURFACE;
	colorScrollbar[] = FLO_COLOR_SCROLLBAR;
	colorSelect[] = FLO_COLOR_SELECT_TEXT;
	colorSelect2[] = FLO_COLOR_SELECT_TEXT;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	colorSelectBackground2[] = FLO_COLOR_PRIMARY;
	colorPicture[] = FLO_COLOR_TEXT;
	colorPictureSelected[] = FLO_COLOR_TEXT;
	colorPictureDisabled[] = FLO_COLOR_TEXT_DISABLED;
	soundSelect[] = {"", 0.1, 1};
	arrowEmpty = "#(argb,8,8,3)color(1,1,1,1)";
	arrowFull = "#(argb,8,8,3)color(1,1,1,1)";
	rowHeight = 0;
	x = 0;
	y = 0;
	w = 0.4;
	h = 0.4;
	shadow = 0;
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	period = 1.2;
	maxHistoryDelay = 1.0;
	autoScrollSpeed = -1;
	autoScrollDelay = 5;
	autoScrollRewind = 0;
	tooltipColorText[] = FLO_COLOR_TOOLTIP_TEXT;
	tooltipColorBox[] = FLO_COLOR_TOOLTIP_BOX;
	tooltipColorShade[] = FLO_COLOR_TOOLTIP_BG;
	class ListScrollBar: FLO_ScrollBar
	{
		autoScrollEnabled = 1;
	};
};

class RscCheckbox
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_CHECKBOXES;
	idc = -1;
	style = 0;
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_INPUT_BG;
	colorTextSelect[] = FLO_COLOR_SUCCESS;
	colorSelectedBG[] = FLO_COLOR_SURFACE_HOVER;
	colorSelect[] = FLO_COLOR_SELECT_TEXT;
	colorTextDisable[] = FLO_COLOR_TEXT_DISABLED;
	colorDisable[] = FLO_COLOR_TEXT_DISABLED;
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	rows = 1;
	columns = 1;
	strings[] = {""};
	checked_strings[] = {"X"};
	x = 0;
	y = 0;
	w = 0.04;
	h = 0.029412;
};

class RscSlider
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_SLIDER;
	idc = -1;
	style = SL_HORZ;
	color[] = FLO_COLOR_SCROLLBAR;
	colorActive[] = FLO_COLOR_SCROLLBAR_ACTIVE;
	shadow = 0;
	x = 0;
	y = 0;
	w = 0.3;
	h = 0.025;
};

class RscXSlider
{
	type = CT_XSLIDER;
	idc = -1;
	style = SL_HORZ;
	arrowEmpty = "\A3\ui_f\data\gui\cfg\slider\arrowEmpty_ca.paa";
	arrowFull = "\A3\ui_f\data\gui\cfg\slider\arrowFull_ca.paa";
	border = "\A3\ui_f\data\gui\cfg\slider\border_ca.paa";
	thumb = "\A3\ui_f\data\gui\cfg\slider\thumb_ca.paa";
	color[] = FLO_COLOR_SURFACE;
	colorActive[] = FLO_COLOR_PRIMARY;
	x = 0;
	y = 0;
	w = 0.3;
	h = 0.025;
};

class RscTree
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_TREE;
	idc = -1;
	style = TR_SHOWROOT;
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_SURFACE;
	colorSelect[] = FLO_COLOR_SELECT_TEXT;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	colorMarked[] = FLO_COLOR_WARNING;
	colorMarkedSelected[] = FLO_COLOR_WARNING;
	colorBorder[] = FLO_COLOR_BORDER;
	font = "RobotoCondensed";
	sizeEx = GUI_TEXT_SIZE_MEDIUM;
	shadow = 1;
	expandedTexture = "\A3\ui_f\data\gui\rsccommon\rsctree\expandedTexture_ca.paa";
	hiddenTexture = "\A3\ui_f\data\gui\rsccommon\rsctree\hiddenTexture_ca.paa";
	x = 0;
	y = 0;
	w = 0.3;
	h = 0.3;
	rowHeight = 0.03;
	colorSelectText[] = FLO_COLOR_TEXT;
	colorMarkedText[] = FLO_COLOR_TEXT;
	multiselectEnabled = 0;
	class ScrollBar: FLO_ScrollBar {};
};

class RscControlsGroup
{
	deletable = 0;
	fade = 0;
	type = CT_CONTROLS_GROUP;
	idc = -1;
	style = ST_MULTI;
	x = 0;
	y = 0;
	w = 1;
	h = 1;
	class ScrollBar: FLO_ScrollBar {};
	class HScrollBar: FLO_ScrollBar
	{
		height = 0.028;
	};
	class VScrollBar: FLO_ScrollBar
	{
		width = 0.021;
	};
	class Controls {};
};

class RscMap
{
	deletable = 0;
	fade = 0;
	access = 0;
	type = CT_MAP;
	idc = -1;
	style = ST_LEFT;
	colorBackground[] = {0.969, 0.957, 0.949, 1};
	colorOutside[] = {0, 0, 0, 1};
	colorText[] = {0, 0, 0, 1};
	colorSea[] = {0.467, 0.631, 0.851, 0.5};
	colorForest[] = {0.624, 0.78, 0.388, 0.5};
	colorForestBorder[] = {0, 0, 0, 0};
	colorRocks[] = {0, 0, 0, 0.3};
	colorRocksBorder[] = {0, 0, 0, 0};
	colorLevels[] = {0.286, 0.177, 0.094, 0.5};
	colorMainCountlines[] = {0.572, 0.354, 0.188, 0.5};
	colorCountlines[] = {0.572, 0.354, 0.188, 0.25};
	colorMainCountlinesWater[] = {0.491, 0.577, 0.702, 0.6};
	colorCountlinesWater[] = {0.491, 0.577, 0.702, 0.3};
	colorPowerLines[] = {0.1, 0.1, 0.1, 1};
	colorRailWay[] = {0.8, 0.2, 0, 1};
	colorNames[] = {0.1, 0.1, 0.1, 0.9};
	colorInactive[] = {1, 1, 1, 0.5};
	colorGrid[] = {0.1, 0.1, 0.1, 0.6};
	colorGridMap[] = {0.1, 0.1, 0.1, 0.6};
	font = "RobotoCondensed";
	sizeEx = 0.04;
	stickX[] = {0.2, {"Gamma", 1, 1.5}};
	stickY[] = {0.2, {"Gamma", 1, 1.5}};
	ptsPerSquareSea = 5;
	ptsPerSquareTxt = 3;
	ptsPerSquareCLn = 10;
	ptsPerSquareExp = 10;
	ptsPerSquareCost = 10;
	ptsPerSquareFor = 9;
	ptsPerSquareForEdge = 9;
	ptsPerSquareRoad = 6;
	ptsPerSquareObj = 9;
	showCountourInterval = 0;
	scaleMin = 0.001;
	scaleMax = 1;
	scaleDefault = 0.16;
	maxSatelliteAlpha = 0.85;
	alphaFadeStartScale = 0.35;
	alphaFadeEndScale = 0.4;
	x = 0;
	y = 0;
	w = 1;
	h = 1;
};

// ============================================================================
// INCLUDE FLO STYLED CONTROLS
// ============================================================================

#include "FLO_controls.hpp"
