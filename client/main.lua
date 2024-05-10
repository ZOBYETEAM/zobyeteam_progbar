local tasks = {}

--[[  
     
    local isFinished = exports['zobyeteam_progbar']:play({
        disableInterface = false,
        name = 'premiumjob',
        label = 'กำลังทำงาน',
        duration = pickTime,
        useWhileDead = false,
        cancelable = true,
        controlDisables = {
            movement = true,
            vehicle = true,
            mouse = false,
            combat = true,
        },
        animation = {
            dict = v.animation.dict,
            anim = v.animation.anim,
            flags = 0,
            task = nil,
        },
        prop = v.prop,
    })
 
]]

function play(options)
    if not options.name then return end
    if not options.duration then return end
    if not options.label then return end
    
    if tasks[options.name] then return end
    
    local playerPed = PlayerPedId()
    
    if IsEntityDead(playerPed) and not options.useWhileDead then return end
    
    tasks[options.name] = options
    
    -- Animation
    if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
        if options.animation and options.animation.dict and options.animation.anim then
            -- Set default value for flags
            options.animation.flags = options.animation.flags or 0
            
            local isPlayingAnim = false
            
            for _, v in pairs(tasks) do
                if IsEntityPlayingAnim(playerPed, v.animation.dict, v.animation.anim, v.animation.flags) then
                    isPlayingAnim = true
                    break
                end
            end
            
            if not isPlayingAnim then
                loadAnimDict(options.animation.dict)
                TaskPlayAnim(playerPed, options.animation.dict, options.animation.anim, 3.0, 1.0, -1, options.animation.flags, 0, 0, 0, 0)
            end
        end
    end
    
    local netId = nil
    
    -- Props
    if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
        if options.prop and options.prop.model then
            -- Set default value
            options.prop.bone = options.prop.bone or 60309
            options.prop.coords = options.prop.coords or vector3(0.0, 0.0, 0.0)
            options.prop.rotation = options.prop.rotation or vector3(0.0, 0.0, 0.0)
            
            CreateThread(function()
                loadModel(options.prop.model)
                
                local pCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, 0.0)
                local object = CreateObject(GetHashKey(options.prop.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)
                
                netId = ObjToNet(object)
                SetNetworkIdExistsOnAllMachines(netId, true)
                NetworkSetNetworkIdDynamic(netId, true)
                SetNetworkIdCanMigrate(netId, false)
                
                AttachEntityToEntity(object, playerPed, GetPedBoneIndex(playerPed, options.prop.bone), options.prop.coords, options.prop.rotation, 1, 1, 0, 1, 0, 1)
                
                Wait(options.duration)
                
                DetachEntity(NetToObj(netId), 1, 1)
                DeleteEntity(NetToObj(netId))
            end)
        end
    end
    
    if not options.disableInterface then
        SendNUIMessage({
            action = 'play',
            name = options.name,
            label = options.label,
            duration = options.duration
        })
    end

    local isFinished = playPromise(options)

    ClearPedTasks(playerPed)
    StopAnimTask(playerPed, options.animDict, options.anim, 1.0)

    if not isFinished and not options.disableInterface then 
        SendNUIMessage({
            action = 'stop',
            name = options.name
        })
    end

    if netId then 
        DetachEntity(NetToObj(netId), 1, 1)
        DeleteEntity(NetToObj(netId))
    end
    
    tasks[options.name] = nil

    return isFinished
end

function playPromise(options)
    local promiseClient = promise.new()
    
    local isPlayTimeout = true
    
    SetTimeout(options.duration, function()
        if isPlayTimeout then 
            promiseClient:resolve(true)
        end
        isPlayTimeout = false
    end)

    CreateThread(function()
        while isPlayTimeout do
            if IsControlJustPressed(0, 186) and options.cancelable then
                isPlayTimeout = false
                return promiseClient:resolve(false)
            end

            if not tasks[options.name] then 
                isPlayTimeout = false
                return promiseClient:resolve(false)
            end
            
            if options.controlDisables then
                if options.controlDisables.movement then
                    DisableControlAction(0, 30, true)-- disable left/right
                    DisableControlAction(0, 31, true)-- disable forward/back
                    DisableControlAction(0, 36, true)-- INPUT_DUCK
                    DisableControlAction(0, 21, true)-- disable sprint
                end
                
                if options.controlDisables.vehicle then
                    DisableControlAction(0, 63, true)-- veh turn left
                    DisableControlAction(0, 64, true)-- veh turn right
                    DisableControlAction(0, 71, true)-- veh forward
                    DisableControlAction(0, 72, true)-- veh backwards
                    DisableControlAction(0, 75, true)-- disable exit vehicle
                end
                
                if options.controlDisables.mouse then
                    DisableControlAction(0, 1, true)-- LookLeftRight
                    DisableControlAction(0, 2, true)-- LookUpDown
                    DisableControlAction(0, 106, true)-- VehicleMouseControlOverride
                end
                
                if options.controlDisables.combat then
                    DisablePlayerFiring(playerPed, true)-- Disable weapon firing
                    DisableControlAction(0, 24, true)-- disable attack
                    DisableControlAction(0, 25, true)-- disable aim
                    DisableControlAction(1, 37, true)-- disable weapon select
                    DisableControlAction(0, 47, true)-- disable weapon
                    DisableControlAction(0, 58, true)-- disable weapon
                    DisableControlAction(0, 140, true)-- disable melee
                    DisableControlAction(0, 141, true)-- disable melee
                    DisableControlAction(0, 142, true)-- disable melee
                    DisableControlAction(0, 143, true)-- disable melee
                    DisableControlAction(0, 263, true)-- disable melee
                    DisableControlAction(0, 264, true)-- disable melee
                    DisableControlAction(0, 257, true)-- disable melee
                end
            end
            
            Wait(0)
        end
    end)
    
    return Citizen.Await(promiseClient)
end

function stop(key) 
    if isPlaying(key) then 
        tasks[key] = nil
    end
end

function isPlaying(key)
    -- Check all task because don't have target key
    if not key then
        for k, v in pairs(tasks) do
            if v then
                return true
            end
        end
        
        return false
    end
    
    return tasks[key] and true or false
end
