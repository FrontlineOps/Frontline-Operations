/*
 * FLO UI Constants
 * Author: Frontline Operations
 * 
 * Description:
 * Centralized UI constants including color palette, font sizes, spacing,
 * and IDD/IDC ranges. All FLO dialogs should use these constants.
 */

// ============================================================================
// COLOR PALETTE
// ============================================================================

// Primary brand colors (deep red theme)
#define FLO_COLOR_PRIMARY           {0.50, 0.10, 0.10, 1.00}
#define FLO_COLOR_PRIMARY_HOVER     {0.60, 0.15, 0.15, 1.00}
#define FLO_COLOR_ACCENT            {0.85, 0.35, 0.35, 1.00}

// Neutral/background colors
#define FLO_COLOR_BACKGROUND        {0.08, 0.08, 0.08, 0.92}
#define FLO_COLOR_BACKGROUND_SOLID  {0.06, 0.06, 0.06, 1.00}
#define FLO_COLOR_SURFACE           {0.12, 0.12, 0.12, 1.00}
#define FLO_COLOR_SURFACE_HOVER     {0.18, 0.18, 0.18, 1.00}
#define FLO_COLOR_HEADER            {0.15, 0.15, 0.20, 1.00}
#define FLO_COLOR_BORDER            {0.25, 0.25, 0.25, 1.00}

// Text colors
#define FLO_COLOR_TEXT              {1.00, 1.00, 1.00, 1.00}
#define FLO_COLOR_TEXT_SECONDARY    {0.85, 0.85, 0.85, 1.00}
#define FLO_COLOR_TEXT_MUTED        {0.70, 0.70, 0.70, 1.00}
#define FLO_COLOR_TEXT_DISABLED     {0.50, 0.50, 0.50, 1.00}
#define FLO_COLOR_TEXT_TITLE        {0.85, 0.35, 0.35, 1.00}

// Semantic colors
#define FLO_COLOR_SUCCESS           {0.35, 0.85, 0.35, 1.00}
#define FLO_COLOR_SUCCESS_BG        {0.15, 0.35, 0.15, 1.00}
#define FLO_COLOR_WARNING           {0.85, 0.65, 0.20, 1.00}
#define FLO_COLOR_WARNING_BG        {0.35, 0.25, 0.10, 1.00}
#define FLO_COLOR_DANGER            {0.85, 0.25, 0.25, 1.00}
#define FLO_COLOR_DANGER_HOVER      {1.00, 0.35, 0.35, 1.00}
#define FLO_COLOR_INFO              {0.48, 0.76, 1.00, 1.00}
#define FLO_COLOR_INFO_BG           {0.15, 0.25, 0.40, 1.00}

// Interactive element colors
#define FLO_COLOR_BUTTON_BG         {0.20, 0.20, 0.20, 1.00}
#define FLO_COLOR_BUTTON_HOVER      {0.30, 0.30, 0.30, 1.00}
#define FLO_COLOR_BUTTON_ACTIVE     {0.35, 0.35, 0.35, 1.00}
#define FLO_COLOR_BUTTON_DISABLED   {0.15, 0.15, 0.15, 1.00}

#define FLO_COLOR_INPUT_BG          {0.10, 0.10, 0.10, 1.00}
#define FLO_COLOR_INPUT_BORDER      {0.30, 0.30, 0.30, 1.00}
#define FLO_COLOR_INPUT_FOCUS       {0.50, 0.20, 0.20, 1.00}

#define FLO_COLOR_SCROLLBAR         {0.40, 0.40, 0.40, 0.80}
#define FLO_COLOR_SCROLLBAR_ACTIVE  {0.60, 0.60, 0.60, 1.00}

// Selection colors
#define FLO_COLOR_SELECT_BG         {0.50, 0.15, 0.15, 0.85}
#define FLO_COLOR_SELECT_TEXT       {1.00, 1.00, 1.00, 1.00}

// Tooltip colors
#define FLO_COLOR_TOOLTIP_TEXT      {1.00, 1.00, 1.00, 1.00}
#define FLO_COLOR_TOOLTIP_BOX       {0.50, 0.50, 0.50, 1.00}
#define FLO_COLOR_TOOLTIP_BG        {0.00, 0.00, 0.00, 0.85}

// Transparent
#define FLO_COLOR_TRANSPARENT       {0.00, 0.00, 0.00, 0.00}

// ============================================================================
// FONT SIZES (Responsive)
// ============================================================================

#define FLO_FONT_SIZE_XS    "(((safezoneW / safezoneH) min 1.2) / 1.2 / 25 * 0.60)"
#define FLO_FONT_SIZE_SM    "(((safezoneW / safezoneH) min 1.2) / 1.2 / 25 * 0.75)"
#define FLO_FONT_SIZE       "(((safezoneW / safezoneH) min 1.2) / 1.2 / 25 * 0.90)"
#define FLO_FONT_SIZE_LG    "(((safezoneW / safezoneH) min 1.2) / 1.2 / 25 * 1.10)"
#define FLO_FONT_SIZE_XL    "(((safezoneW / safezoneH) min 1.2) / 1.2 / 25 * 1.40)"
#define FLO_FONT_SIZE_XXL   "(((safezoneW / safezoneH) min 1.2) / 1.2 / 25 * 1.80)"

// ============================================================================
// SPACING & COMPONENT SIZES (Use with GUI_GRID_W/H)
// ============================================================================

#define FLO_UI_MARGIN_XS    (0.25 * GUI_GRID_W)
#define FLO_UI_MARGIN_SM    (0.50 * GUI_GRID_W)
#define FLO_UI_MARGIN       (1.00 * GUI_GRID_W)
#define FLO_UI_MARGIN_LG    (2.00 * GUI_GRID_W)
#define FLO_UI_MARGIN_XL    (4.00 * GUI_GRID_W)

#define FLO_UI_BUTTON_H     (1.20 * GUI_GRID_H)
#define FLO_UI_BUTTON_W     (8.00 * GUI_GRID_W)
#define FLO_UI_BUTTON_SM_W  (5.00 * GUI_GRID_W)
#define FLO_UI_BUTTON_LG_W  (12.0 * GUI_GRID_W)

#define FLO_UI_INPUT_H      (1.20 * GUI_GRID_H)
#define FLO_UI_HEADER_H     (1.50 * GUI_GRID_H)
#define FLO_UI_COMBO_H      (1.20 * GUI_GRID_H)
#define FLO_UI_LISTBOX_ROW  (1.00 * GUI_GRID_H)

#define FLO_UI_CLOSE_BTN_W  (1.50 * GUI_GRID_W)

// ============================================================================
// IDD RANGES (Dialog IDs)
// ============================================================================

// Mission Setup dialogs (900-999)
#define FLO_IDD_FACTION_SELECT      999

// Gameplay dialogs (1000-1499)
#define FLO_IDD_INTEL_VIEW          1000
#define FLO_IDD_MISSION_STATUS      1001

// Request Menu (1500-1599)
#define FLO_IDD_REQUEST             1599  // Main request menu (backward compatible)
#define FLO_IDD_REQUEST_OP          1598  // OP-specific variant (reserved)

// Reserved for future use (1600-1899)

// IDS_Logistics (9500-9599)
#define FLO_IDD_BUILD_MENU          9500  // Build menu dialog (existing)

// IDS_Notifications (3000-3999)
#define FLO_IDD_NOTIFICATIONS       3000

// ============================================================================
// IDC RANGES (Control IDs within dialogs)
// ============================================================================

// Faction Dialog Controls (1950-1999)
#define FLO_IDC_FACTION_COMBO_PLAYER     1955
#define FLO_IDC_FACTION_COMBO_ENEMY      1956
#define FLO_IDC_FACTION_COMBO_CIVILIAN   1957
#define FLO_IDC_FACTION_COMBO_PRESENCE   1958
#define FLO_IDC_FACTION_COMBO_RESOURCES  1959
#define FLO_IDC_FACTION_COMBO_REPUTATION 1960
#define FLO_IDC_FACTION_COMBO_DIFFICULTY 1961
#define FLO_IDC_FACTION_COMBO_GTN_DEFENSE 1962
#define FLO_IDC_FACTION_COMBO_GTN_TEMPO 1963
#define FLO_IDC_FACTION_BTN_START        1600
#define FLO_IDC_FACTION_BTN_CLOSE        1601

// Request Menu Dialog Controls
#define FLO_IDC_REQUEST_RESOURCES        1000
#define FLO_IDC_REQUEST_RESISTANCE       1001
#define FLO_IDC_REQUEST_AGGRESSION       1002
#define FLO_IDC_REQUEST_TITLE            1004
#define FLO_IDC_REQUEST_LABEL_GROUND     1005
#define FLO_IDC_REQUEST_LABEL_AIR        1006
#define FLO_IDC_REQUEST_LABEL_SUPPLIES   1007
#define FLO_IDC_REQUEST_BTN_CLOSE        1600
#define FLO_IDC_REQUEST_BTN_GROUND       1602
#define FLO_IDC_REQUEST_BTN_AIR          1603
#define FLO_IDC_REQUEST_BTN_SUPPLIES     1604
#define FLO_IDC_REQUEST_BTN_FOB          1888
#define FLO_IDC_REQUEST_BTN_OP           1999
#define FLO_IDC_REQUEST_LIST_GROUND      2101
#define FLO_IDC_REQUEST_LIST_AIR         2102
#define FLO_IDC_REQUEST_LIST_SUPPLIES    2103

// Common control ID patterns
#define FLO_IDC_NONE                     -1
