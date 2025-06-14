-- This is the Main tab that appears in the Character Info screen, after the Temperature tab

require "HomeInventoryManager"
require "HomeInventoryPanel"
require "XpSystem/ISUI/ISCharacterInfoWindow"
require "AddHomeInventoryZoneUI"

-- -- Backup the original function
local old_createChildren = ISCharacterInfoWindow.createChildren

-- Override the function  to include the new Home Inventory Panel
function ISCharacterInfoWindow:createChildren(...)
    -- Call the original function
    old_createChildren(self, ...)

    -- Add HomeInventoryPanel
    -- Only add once, and only for the main player
    if self.playerNum == 0 and not self.homeInventoryTab then
        local homeInventoryViewName = getText("UI_HomeInventory_TabName")

        self.homeInventoryView = HomeInventoryPanel:new(0, 8, tabTotalWidth, self.height-8, self.playerNum);
        self.homeInventoryView:initialise()
        self.homeInventoryView.infoText = getTextOrNull("UI_HomeInventory_MainPanelInfowa");
        self.panel:addView(homeInventoryViewName, self.homeInventoryView) -- panel is an ISTabPanel object

        -- Set the correct size before restoring the layout. Currently, ISCharacterScreen:render sets the height/width.
        self:setWidth(self.charScreen.width)
        self:setHeight(self.charScreen.height);

        -- I'm hooking into the onActivateView callback for these panels. I wish I could
        -- find the callback for when you hover over the tab and expand it. Though maybe
        -- it doesn't even exist
        local old_onActivateView = self.panel.onActivateView
        self.panel.onActivateView = function(target, tabPanel)
            if old_onActivateView then
                old_onActivateView(target, tabPanel)
            end

            local viewName = tabPanel.activeView.name

            if viewName == homeInventoryViewName then -- only recalculate if it's the correct tab
                self.homeInventoryView:populateList()
            end
        end
    end
end