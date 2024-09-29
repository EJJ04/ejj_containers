for item, prefix in pairs(Config.ContainerPrefixes) do
    exports('openContainer:' .. item, function(data, slot)
        if not slot or not slot.metadata or not slot.metadata.identifier then
            print('Generating new identifier')
            local identifier = lib.callback.await('ejj_containers:getNewIdentifier', 100, data.slot, item)

            if identifier then
                print('New identifier generated:', identifier)
                exports.ox_inventory:openInventory('stash', prefix .. identifier)
            else
                print('Failed to generate new identifier')
            end
        else
            print('Opening existing container')
            TriggerServerEvent('ejj_containers:openContainer', slot.metadata.identifier, item)
            exports.ox_inventory:openInventory('stash', prefix .. slot.metadata.identifier)
        end
    end)
end
