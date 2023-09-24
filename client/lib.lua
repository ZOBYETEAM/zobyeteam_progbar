function loadModel(modelHash)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        RequestModel(modelHash)
        Wait(5)
    end
end

function loadAnimDict(dict)
    HasAnimDictLoaded(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end