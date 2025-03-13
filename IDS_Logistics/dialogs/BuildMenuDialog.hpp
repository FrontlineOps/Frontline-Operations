#include "Defines.hpp"

class IDS_Logistics_BuildMenuDialog {
    idd = 9500;
    movingEnable = 0;
    enableSimulationGlobal = 1;
    onLoad = "[_this select 0] call IDS_Logistics_fnc_handlePreview;";

    class Objects {
        class Entity: RscEntity {
            idc = 9506;
            type = 82;
            model = "\A3\Structures_F\Mil\Cargo\Cargo_HQ_V1_F.p3d"; // Default model
            scale = 0.01;
            direction[] = {0, -0.35, -0.65};
            up[] = {0, 0.65, -0.35};
            
            // Using exact coordinates from working version
            x = 0.285 * safezoneW + safezoneX;
            y = 0.45 * safezoneH + safezoneY;
            z = 0.2;
            
            xBack = 0.285 * safezoneW + safezoneX;
            yBack = 0.45 * safezoneH + safezoneY;
            zBack = 0.5;
            
            inBack = 1;
            enableZoom = 0;
            zoomDuration = 0.001;
            shadow = 0;
            access = 0;
        };
    };
    
    class ControlsBackground {
        class Background: IGUIBack {
            idc = -1;
            x = 0.1 * safezoneW + safezoneX;
            y = 0.15 * safezoneH + safezoneY;
            w = 0.8 * safezoneW;
            h = 0.7 * safezoneH;
            colorBackground[] = {0.1, 0.1, 0.1, 0.8};
        };
        
        class HeaderBackground: IGUIBack {
            idc = -1;
            x = 0.1 * safezoneW + safezoneX;
            y = 0.15 * safezoneH + safezoneY;
            w = 0.8 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.4, 0.4, 0.4, 1};
        };
        
        // Left side preview section background with distinct color
        class PreviewBackground: IGUIBack {
            idc = -1;
            x = 0.11 * safezoneW + safezoneX;
            y = 0.21 * safezoneH + safezoneY;
            w = 0.35 * safezoneW;
            h = 0.62 * safezoneH;
            colorBackground[] = {0.18, 0.18, 0.2, 0.9};
        };
        
        // Preview frame with subtle blue accent
        class PreviewFrame: RscFrame {
            idc = -1;
            x = 0.12 * safezoneW + safezoneX;
            y = 0.22 * safezoneH + safezoneY;
            w = 0.33 * safezoneW;
            h = 0.46 * safezoneH;
            colorText[] = {0.5, 0.7, 0.9, 1};
        };
        
        // Right side content background with distinct color
        class RightSideBackground: IGUIBack {
            idc = -1;
            x = 0.47 * safezoneW + safezoneX;
            y = 0.21 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.62 * safezoneH;
            colorBackground[] = {0.2, 0.2, 0.18, 0.9};
        };
    };
    
    class Controls {
        class Title: RscText {
            idc = -1;
            text = "Base Building - Select Entity";
            x = 0.1 * safezoneW + safezoneX;
            y = 0.15 * safezoneH + safezoneY;
            w = 0.8 * safezoneW;
            h = 0.05 * safezoneH;
            colorText[] = {1, 1, 1, 1};
            sizeEx = 0.04;
            style = ST_CENTER;
        };
        
        // LEFT SIDE - Preview label and entity info
        class PreviewSectionFrame: RscFrame {
            idc = -1;
            x = 0.11 * safezoneW + safezoneX;
            y = 0.21 * safezoneH + safezoneY;
            w = 0.35 * safezoneW;
            h = 0.62 * safezoneH;
            colorText[] = {0.7, 0.7, 0.7, 1};
        };
        
        class PreviewLabel: RscText {
            idc = -1;
            text = "Preview";
            x = 0.12 * safezoneW + safezoneX;
            y = 0.21 * safezoneH + safezoneY;
            w = 0.33 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.9, 0.9, 1, 1};
            sizeEx = 0.035;
            style = ST_CENTER;
        };
        
        class EntityInfoLabel: RscText {
            idc = -1;
            text = "Entity Information";
            x = 0.12 * safezoneW + safezoneX;
            y = 0.685 * safezoneH + safezoneY;
            w = 0.33 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.9, 0.9, 1, 1};
            sizeEx = 0.03;
            style = ST_CENTER;
        };
        
        class EntityInfo: RscStructuredText {
            idc = 9504;
            x = 0.12 * safezoneW + safezoneX;
            y = 0.715 * safezoneH + safezoneY;
            w = 0.33 * safezoneW;
            h = 0.105 * safezoneH;
            colorBackground[] = {0.15, 0.15, 0.17, 1};
            size = 0.03;
        };
        
        // RIGHT SIDE with frames for visual distinction
        class RightSideFrame: RscFrame {
            idc = -1;
            x = 0.47 * safezoneW + safezoneX;
            y = 0.21 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.62 * safezoneH;
            colorText[] = {0.7, 0.7, 0.7, 1};
        };
        
        // Categories section
        class CategorySectionFrame: RscFrame {
            idc = -1;
            x = 0.48 * safezoneW + safezoneX;
            y = 0.22 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.19 * safezoneH;
            colorText[] = {0.6, 0.8, 0.6, 1};
        };
        
        class CategoryLabel: RscText {
            idc = -1;
            text = "Categories";
            x = 0.48 * safezoneW + safezoneX;
            y = 0.22 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.8, 1, 0.8, 1};
            sizeEx = 0.035;
            style = ST_CENTER;
        };
        
        class CategoryList: RscListBox {
            idc = 9501;
            x = 0.48 * safezoneW + safezoneX;
            y = 0.26 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.15 * safezoneH;
            colorBackground[] = {0.17, 0.17, 0.15, 1};
            rowHeight = 0.05;
            sizeEx = 0.03;
            onLBSelChanged = "_this call IDS_Logistics_fnc_updateEntityList";
        };
        
        // Search box - keeping original position
        class SearchSectionFrame: RscFrame {
            idc = -1;
            x = 0.48 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.7, 0.7, 0.8, 1};
        };
        
        class SearchLabel: RscText {
            idc = -1;
            text = "Search:";
            x = 0.48 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.1 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {1, 1, 1, 1};
            sizeEx = 0.03;
        };
        
        class SearchEdit: RscEdit {
            idc = 9502;
            x = 0.58 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.3 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.3, 0.3, 0.3, 1};
            text = "";
            tooltip = "Search entities";
            onKeyUp = "_this call IDS_Logistics_fnc_searchEntities";
        };
        
        // Entities section
        class EntitiesSectionFrame: RscFrame {
            idc = -1;
            x = 0.48 * safezoneW + safezoneX;
            y = 0.46 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.28 * safezoneH;
            colorText[] = {0.8, 0.6, 0.6, 1};
        };
        
        class EntitiesLabel: RscText {
            idc = -1;
            text = "Entities";
            x = 0.48 * safezoneW + safezoneX;
            y = 0.46 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {1, 0.8, 0.8, 1};
            sizeEx = 0.035;
            style = ST_CENTER;
        };
        
        class EntitiesList: RscListBox {
            idc = 9503;
            x = 0.48 * safezoneW + safezoneX;
            y = 0.5 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.24 * safezoneH;
            colorBackground[] = {0.17, 0.15, 0.15, 1};
            rowHeight = 0.05;
            sizeEx = 0.03;
            onLBSelChanged = "_this call IDS_Logistics_fnc_updatePreview";
        };
        
        // Buttons section with a distinct background
        class ButtonsBackground: IGUIBack {
            idc = -1;
            x = 0.47 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.08 * safezoneH;
            colorBackground[] = {0.22, 0.22, 0.22, 1};
        };
        
        class ButtonsFrame: RscFrame {
            idc = -1;
            x = 0.47 * safezoneW + safezoneX;
            y = 0.75 * safezoneH + safezoneY;
            w = 0.42 * safezoneW;
            h = 0.08 * safezoneH;
            colorText[] = {0.7, 0.7, 0.7, 1};
        };
        
        class SelectButton: RscButton {
            idc = 9505;
            text = "Select";
            x = 0.48 * safezoneW + safezoneX;
            y = 0.765 * safezoneH + safezoneY;
            w = 0.19 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.2, 0.6, 0.2, 1};
            colorBackgroundActive[] = {0.2, 0.8, 0.2, 1};
            action = "call IDS_Logistics_fnc_selectEntity";
            sizeEx = 0.04;
        };
        
        class CancelButton: RscButton {
            idc = -1;
            text = "Cancel";
            x = 0.68 * safezoneW + safezoneX;
            y = 0.765 * safezoneH + safezoneY;
            w = 0.2 * safezoneW;
            h = 0.05 * safezoneH;
            colorBackground[] = {0.6, 0.2, 0.2, 1};
            colorBackgroundActive[] = {0.8, 0.2, 0.2, 1};
            action = "closeDialog 0";
            sizeEx = 0.04;
        };
    };
};