for item, prefix in pairs(Config.ContainerPrefixes) do
    exports('openContainer:' .. item, function(data, slot)
        if not slot or not slot.metadata or not slot.metadata.identifier then
            local identifier = lib.callback.await('ejj_containers:getNewIdentifier', 100, data.slot, item)

            if identifier then
                exports.ox_inventory:openInventory('stash', prefix .. identifier)
            else
                print('Failed to generate new identifier')
            end
        else
            TriggerServerEvent('ejj_containers:openContainer', slot.metadata.identifier, item)
            exports.ox_inventory:openInventory('stash', prefix .. slot.metadata.identifier)
        end
    end)
end
