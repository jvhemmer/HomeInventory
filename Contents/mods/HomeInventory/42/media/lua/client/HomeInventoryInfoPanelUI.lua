-- This is the Main tab that appears in the Character Info screen, after the Temperature tab

require "HomeInventoryMain"
require "XpSystem/ISUI/ISCharacterInfoWindow"
require "AddHomeInventoryZoneUI"

-- -- Backup the original function
local old_createChildren = ISCharacterInfoWindow.createChildren

-- Override the function
function ISCharacterInfoWindow:createChildren(...)

    -- Call the original function
    old_createChildren(self, ...)

    -- Only add once, and only for the main player
    if self.playerNum == 0 and not self.homeInventoryTab then

        ----------------------------------------
        -- DIMENSIONS
        ----------------------------------------
        local FIXED_WIDTH = 400
        local FIXED_HEIGHT = 600

        local PADDING = 10

        -- Button dimensions
        local BUTTON_X      = PADDING
        local BUTTON_Y      = PADDING
        local BUTTON_WIDTH  = FIXED_WIDTH - 2*PADDING
        local BUTTON_HEIGHT = 30
        local BUTTON_XEND   = BUTTON_X + BUTTON_WIDTH
        local BUTTON_YEND   = BUTTON_Y + BUTTON_HEIGHT

        -- Search bar dimensions
        local SEARCH_X      = PADDING
        local SEARCH_Y      = BUTTON_YEND + PADDING
        local SEARCH_WIDTH  = BUTTON_WIDTH
        local SEARCH_HEIGHT = 22
        local SEARCH_XEND   = SEARCH_X + SEARCH_WIDTH
        local SEARCH_YEND   = SEARCH_Y + SEARCH_HEIGHT

        -- Scrolling list dimensions 
        local HEADER_PADDING    = 20
        local LIST_X            = 0 -- start at the panel border
        local LIST_Y            = PADDING + SEARCH_Y + SEARCH_HEIGHT + HEADER_PADDING
        local LIST_WIDTH        = FIXED_WIDTH -- end at the panel border (fill)
        local LIST_HEIGHT       = FIXED_HEIGHT - 2 * PADDING - SEARCH_YEND - HEADER_PADDING

        -- Columns
        local COL_NAME_X    = 10
        local COL_AMOUNT_X  = LIST_WIDTH - 210
        local COL_ZONE_X    = LIST_WIDTH - 140
        local COL_INSIDE_X  = LIST_WIDTH - 60

        -- Rows
        local ROW_HEIGHT = 16
    
        ----------------------------------------
        -- CREATE PANEL
        ----------------------------------------
        local HomeInventoryInfoPanel = ISPanel:new(0, 8, FIXED_WIDTH, FIXED_HEIGHT)
        HomeInventoryInfoPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
        HomeInventoryInfoPanel:initialise()

        function HomeInventoryInfoPanel:prerender()
            ISPanel.prerender(self)
            self:setWidth(FIXED_WIDTH)
            self:setHeight(FIXED_HEIGHT)
            if self.parent then
                self.parent:setWidth(FIXED_WIDTH)
                self.parent:setHeight(FIXED_HEIGHT)
                if self.parent.parent then
                    self.parent.parent:setWidth(FIXED_WIDTH)
                    self.parent.parent:setHeight(FIXED_HEIGHT + self.parent.parent:titleBarHeight())
                end
            end

            -- Header for the list
            self:drawText("Name",   COL_NAME_X,   self.itemList.y - ROW_HEIGHT, 1, 1, 1, 1, UIFont.Small)
            self:drawText("Amount", COL_AMOUNT_X, self.itemList.y - ROW_HEIGHT, 1, 1, 1, 1, UIFont.Small)
            self:drawText("Zone",   COL_ZONE_X,   self.itemList.y - ROW_HEIGHT, 1, 1, 1, 1, UIFont.Small)
            self:drawText("Inside", COL_INSIDE_X, self.itemList.y - ROW_HEIGHT, 1, 1, 1, 1, UIFont.Small)
        end

        ----------------------------------------
        -- CREATE BUTTON
        ----------------------------------------
        local manageButton = ISButton:new(PADDING, PADDING, BUTTON_WIDTH, BUTTON_HEIGHT, "Manage home zones", HomeInventoryInfoPanel,
            function(...)
                if _G.HIOnManageButtonClick then
                    return _G.HIOnManageButtonClick(...)
                end
            end
        )
        manageButton:initialise()
        HomeInventoryInfoPanel:addChild(manageButton)

        ----------------------------------------
        -- CREATE SEARCH BAR
        ----------------------------------------
        local searchBar = ISTextEntryBox:new("", SEARCH_X, SEARCH_Y, SEARCH_WIDTH, SEARCH_HEIGHT)
        searchBar:initialise()
        searchBar:instantiate()
        searchBar:setClearButton(true)
        HomeInventoryInfoPanel:addChild(searchBar)
        HomeInventoryInfoPanel.searchBar = searchBar

        -- Adjust list position to be below the search bar
        -- local LIST_Y = SEARCH_Y + SEARCH_HEIGHT + PADDING
        -- local LIST_HEIGHT = FIXED_HEIGHT - LIST_Y - PADDING

        ----------------------------------------
        -- CREATE LIST (header in draw in panel's prerender above)
        ----------------------------------------
        local itemList = ISScrollingListBox:new(LIST_X, LIST_Y, LIST_WIDTH, LIST_HEIGHT)
        itemList:initialise()
        itemList:instantiate()
        itemList.itemheight = ROW_HEIGHT
        itemList.font = UIFont.Small
        itemList.doDrawItem = function(self, y, item, alt)
            self:drawText(item.item.text,   COL_NAME_X,   y + 2, 1, 1, 1, 1, self.font)
            self:drawText(tostring(item.item.amount), COL_AMOUNT_X, y + 2, 1, 1, 1, 1, self.font)
            self:drawText(item.item.zone,   COL_ZONE_X,   y + 2, 1, 1, 1, 1, self.font)
            self:drawText(item.item.inside, COL_INSIDE_X, y + 2, 1, 1, 1, 1, self.font)
            return y + ROW_HEIGHT
        end
        itemList.drawBorder = true
        itemList:setVisible(true)
        HomeInventoryInfoPanel:addChild(itemList)
        HomeInventoryInfoPanel.itemList = itemList

        ----------------------------------------
        -- MAIN LOGIC
        ----------------------------------------
        HomeInventoryInfoPanel.allItems = {}

        -- Filtering function
        function HomeInventoryInfoPanel:filterItems()
            local filter = self.searchBar:getText():lower()
            self.itemList:clear()
            for _, v in ipairs(self.allItems) do
                if filter == "" or v.text:lower():find(filter, 1, true) then
                    self.itemList:addItem(v.text, v)
                end
            end
        end

        -- Update filter on text change
        searchBar.onTextChange = function()
            HomeInventoryInfoPanel:filterItems()
        end

        -- Add the tab (the tab name is the label shown on the tab)
        self.panel:addView("Home Inventory", HomeInventoryInfoPanel)
        self.homeInventoryTab = HomeInventoryInfoPanel

        self.panel.target = self.panel -- or any object you want as the first argument
        self.panel.onActivateView = function(target, tabPanel)
            local viewName = tabPanel.activeView.name
            if viewName == "Home Inventory" then
                print("Home Inventory tab opened!")
                HomeInventoryInfoPanel.itemList:clear()
                local itemtable = HomeInventoryManager:getAllItemInfo()
                HomeInventoryInfoPanel.allItems = itemtable
                HomeInventoryInfoPanel:filterItems()
            end
        end
    end

    -- Try to load this shebang
    HomeInventoryManager:load()
end

function HIOnManageButtonClick()

    if not HomeInventoryZonePanel.instance or not HomeInventoryZonePanel.instance:getIsVisible() then
        print("View!")
        local playerObj = getPlayer()
        local playerNum = playerObj:getPlayerNum()
        local ui = HomeInventoryZonePanel:new(
            getPlayerScreenLeft(playerNum) + 100,
            getPlayerScreenTop(playerNum) + 100,
            500,
            500,
            playerObj
        )
        ui:initialise()
        ui:addToUIManager()
    else
        print("Already open!")
        HomeInventoryZonePanel.instance:setVisible(true)
        HomeInventoryZonePanel.instance:bringToTop()
    end

end