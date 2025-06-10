-- This contains the zone manager, mainly to save the data

-- STRUCTURE OF ModData FOR THIS MOD:
-- ModData
-- --HomeInventoryZones
-- ----zones
-- ------name
-- ------x1
-- ------y1
-- ------x2
-- ------y2

HomeInventoryManager = HomeInventoryManager or {}

function HomeInventoryManager:getZones()
    self.zones = self.zones or {}
    return self.zones
end

function HomeInventoryManager:addZone(zone)
    self.zones = self.zones or {}
    table.insert(self.zones, zone)
    self:save()
end

function HomeInventoryManager:removeZone(zone)
    self.zones = self.zones or {}
    for i = #self.zones, 1, -1 do
        if self.zones[i] == zone then
            table.remove(self.zones, i)
            break
        end
    end
    self:save()
end

function HomeInventoryManager:save()
    local md = ModData.getOrCreate("HomeInventoryZones")
    md.zones = self.zones or {}
    ModData.transmit("HomeInventoryZones")

end

function HomeInventoryManager:load()
    local md = ModData.getOrCreate("HomeInventoryZones")
    self.zones = md.zones or {}
end

function HomeInventoryManager:getItemsInZone(zone)
    local items = {}

    for x = math.min(zone.x1, zone.x2), math.max(zone.x1, zone.x2) do
        for y = math.min(zone.y1, zone.y2), math.max(zone.y1, zone.y2) do
            local square = getCell():getGridSquare(x, y, zone.z)
            if square then
                -- Items on the floor
                for i = 0, square:getWorldObjects():size() - 1 do
                    local worldObj = square:getWorldObjects():get(i)
                    if worldObj and worldObj:getItem() then
                        table.insert(items, worldObj:getItem())
                    end
                end
                -- Items in containers
                for i = 0, square:getObjects():size() - 1 do
                    local obj = square:getObjects():get(i)
                    if obj and obj:getContainer() then
                        local container = obj:getContainer()
                        for j = 0, container:getItems():size() - 1 do
                            local item = container:getItems():get(j)
                            table.insert(items, item)
                        end
                    end
                end
            end
        end
    end

    -- -- Debug
    -- for _, item in pairs(items) do
    --     print(item)
    -- end

    return items
end

-- function HomeInventoryManager:getItemsInAllZones()
--     local zones = HomeInventoryManager:getZones()

--     local items = {}

--     for i, zone in ipairs(zones) do
--         local itemsInZone = HomeInventoryManager:getItemsInZone(zone)
--         if itemsInZone then
--             table.insert(items, itemsInZone)
--         end
--     end

--     return items
-- end

Events.OnInitWorld.Add(function() HomeInventoryManager:load() end)