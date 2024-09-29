local registeredStashes = {}
local ox_inventory = exports.ox_inventory

lib.locale()

local function GenerateSerial()
    return ('%s%s%s'):format(math.random(100000, 999999), string.char(math.random(65, 90), math.random(65, 90), math.random(65, 90)), math.random(100000, 999999))
end

local function registerStash(identifier, item)
    if not registeredStashes[identifier] then
        local prefix = Config.ContainerPrefixes[item] or 'custom_' 
        local slots = Config.ContainerItems[item].slots
        local weight = Config.ContainerItems[item].weight

        ox_inventory:RegisterStash(prefix .. identifier, item, slots, weight, false)
        registeredStashes[identifier] = true
    end
end

RegisterServerEvent('ejj_containers:openContainer')
AddEventHandler('ejj_containers:openContainer', function(identifier, item)
    registerStash(identifier, item)
end)

lib.callback.register('ejj_containers:getNewIdentifier', function(source, slot, item)
    print("Generating new identifier for item:", item)
    local newId = GenerateSerial()
    ox_inventory:SetMetadata(source, slot, { identifier = newId })
    registerStash(newId, item)
    return newId
end)

local function containsContainerPrefix(destination)
    for _, prefix in pairs(Config.ContainerPrefixes) do
        if string.find(destination, prefix) then
            return true
        end
    end
    return false
end

local swapHook = ox_inventory:registerHook('swapItems', function(payload)
    local start, destination, move_type = payload.fromInventory, payload.toInventory, payload.toType
    local count_containers = 0

    for item, _ in pairs(Config.ContainerItems) do
        count_containers = count_containers + ox_inventory:GetItem(payload.source, item, nil, true)
    end

    for item, prefix in pairs(Config.ContainerPrefixes) do
        if string.find(destination, prefix) then
            TriggerClientEvent('ox_lib:notify', payload.source, {
                type = 'error',
                title = locale('action_incomplete'),
                description = locale('container_in_container')
            })
            return false
        end
    end

    if Config.OneBagInInventory and count_containers > 0 and move_type == 'player' and destination ~= start then
        TriggerClientEvent('ox_lib:notify', payload.source, {
            type = 'error',
            title = locale('action_incomplete'),
            description = locale('one_container_only') 
        })
        return false
    end

    return true
end, {
    print = false,
    itemFilter = Config.ContainerItems 
})

if Config.OneBagInInventory then
    local createHook = ox_inventory:registerHook('createItem', function(payload)
        local count_containers = 0

        for item, _ in pairs(Config.ContainerItems) do
            count_containers = count_containers + ox_inventory:GetItem(payload.source, item, nil, true)
        end

        if count_containers > 0 then
            local slot = nil
            local playerItems = ox_inventory:GetInventoryItems(payload.source) 

            for _, k in pairs(playerItems) do
                if Config.ContainerItems[k.name] then
                    slot = k.slot
                    break
                end
            end

            Citizen.CreateThread(function()
                local inventoryId = payload.source 
                local dontRemove = slot
                Citizen.Wait(1000)

                for _, k in pairs(ox_inventory:GetInventoryItems(inventoryId)) do
                    if Config.ContainerItems[k.name] and dontRemove ~= nil and k.slot ~= dontRemove then
                        local success = ox_inventory:RemoveItem(inventoryId, k.name, 1, nil, k.slot)
                        if success then
                            TriggerClientEvent('ox_lib:notify', inventoryId, {
                                type = 'error',
                                title = locale('action_incomplete'),
                                description = locale('one_container_only') 
                            })
                        end
                        break
                    end
                end
            end)
        end
    end, {
        print = false,
        itemFilter = Config.ContainerItems 
    })
end

AddEventHandler('onResourceStop', function()
    ox_inventory:removeHooks(swapHook)
    if Config.OneBagInInventory then
        ox_inventory:removeHooks(createHook)
    end
end)