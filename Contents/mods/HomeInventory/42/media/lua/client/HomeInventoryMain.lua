-- This contains the zone manager (not the zone manager WINDOW), which handles all the data

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
HomeInventoryManager.zoneItemCache = HomeInventoryManager.zoneItemCache or {}

function HomeInventoryManager:getAllZones()
    self.zones = self.zones or {}
    return self.zones
end

function HomeInventoryManager:addZone(zone)
    self.zones = self.zones or {}
    table.insert(self.zones, zone)
    self:save()
end

function HomeInventoryManager:removeZone(zone)
    local zoneKey = zone.name or (zone.x1 .. "," .. zone.y1 .. "," .. (zone.z or 0))
    self.zoneItemCache[zoneKey] = nil

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
    local zoneKey = zone.name or (zone.x1 .. "," .. zone.y1 .. "," .. (zone.z or 0))
    local items = {}

    if self:isZoneLoaded(zone) then
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
        -- If we found items, update the cache and return them
        if #items > 0 then
            self.zoneItemCache[zoneKey] = items
            return items
        else
            -- Zone loaded but no items found, use cached items if available
            return self.zoneItemCache[zoneKey] or {}
        end
    else
        -- Zone not loaded, use cached items if available
        return self.zoneItemCache[zoneKey] or {}
    end
end

function HomeInventoryManager:getAllItemInfo()
    local itemMap = {}
    for _, zone in ipairs(self:getAllZones()) do
        for _, item in ipairs(self:getItemsInZone(zone)) do
            local name = item:getDisplayName()
            local container = item:getContainer() and item:getContainer():getType() or "Floor"
            local key = name .. "|" .. (zone.name or "Unknown") .. "|" .. container
            if not itemMap[key] then
                itemMap[key] = {text=name, amount=0, zone=zone.name or "Unknown", inside=container}
            end
            itemMap[key].amount = itemMap[key].amount + 1
        end
    end
    -- Convert map to array for UI
    local grouped = {}
    for _, v in pairs(itemMap) do
        table.insert(grouped, v)
    end
    return grouped
end

function HomeInventoryManager:isZoneLoaded(zone)
    local zx1, zx2 = math.min(zone.x1, zone.x2), math.max(zone.x1, zone.x2)
    local zy1, zy2 = math.min(zone.y1, zone.y2), math.max(zone.y1, zone.y2)
    local zz = zone.z or 0

    for x = zx1, zx2 do
        for y = zy1, zy2 do
            if getCell():getGridSquare(x, y, zz) then
                return true -- At least one square is loaded
            end
        end
    end
    return false
end

function HomeInventoryManager:isAnyZoneLoaded()
    for _, zone in ipairs(self:getAllZones()) do
        if self:isZoneLoaded(zone) then
            return true
        end
    end
    return false
end

function HomeInventoryManager:isAllZonesLoaded()
    for _, zone in ipairs(self:getAllZones()) do
        if not self:isZoneLoaded(zone) then
            return false
        end
    end
    return true
end

function HomeInventoryManager:refresh()
    if ISCharacterInfoWindow.instance and ISCharacterInfoWindow.instance.homeInventoryTab then
        ISCharacterInfoWindow.instance.homeInventoryTab:populateList()
    end
end

function HomeInventoryManager:getZoneByName(name)
    self.zones = self.zones or {}
    for _, zone in ipairs(self.zones) do
        if zone.name == name then
            return zone
        end
    end
    return nil
end

Events.OnInitWorld.Add(function() HomeInventoryManager:load() end)