-- Configurações
local teamCheck = false
local fov = 120
local smoothing = 0.2  -- Aumentado para maior rapidez
local predictionFactor = 0.08
local highlightEnabled = false
local lockPart = "Head"  -- Mudado para a cabeça
local Toggle = false
local ToggleKey = Enum.KeyCode.E
local updateInterval = 30  -- Intervalo de atualização em segundos

-- Serviços do Roblox
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Notificação inicial
StarterGui:SetCore("SendNotification", {
    Title = "Aimbot Private",
    Text = "feito por lidok",
    Duration = 5
})

-- Configurações do círculo FOV
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 1
FOVring.Radius = fov
FOVring.Transparency = 0.8
FOVring.Color = Color3.fromRGB(255, 128, 128)
FOVring.Position = workspace.CurrentCamera.ViewportSize / 2

-- Variáveis de estado
local currentTarget = nil
local aimbotEnabled = true
local toggleState = false
local debounce = false
local lastUpdate = 0

-- Função para adicionar ESP (nome do jogador)
local function createESP(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local billboard = Instance.new("BillboardGui")
        local textLabel = Instance.new("TextLabel")

        billboard.Name = "ESP"
        billboard.Adornee = player.Character.Head
        billboard.Size = UDim2.new(1, 0, 1, 0)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true

        textLabel.Parent = billboard
        textLabel.Size = UDim2.new(0, 100, 0, 50)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.Name
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextSize = 14  -- Tamanho do texto ajustado para ser legível e agradável

        billboard.Parent = player.Character
    end
end

-- Função para remover ESP
local function removeESP(player)
    if player.Character and player.Character:FindFirstChild("ESP") then
        player.Character:FindFirstChild("ESP"):Destroy()
    end
end

-- Função para encontrar o jogador mais próximo dentro do FOV e visível
local function getClosest(cframe)
    local ray = Ray.new(cframe.Position, cframe.LookVector).Unit
    local target = nil
    local mag = math.huge
    local screenCenter = workspace.CurrentCamera.ViewportSize / 2

    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild(lockPart) and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v ~= Players.LocalPlayer and (v.Team ~= Players.LocalPlayer.Team or (not teamCheck)) then
            local screenPoint, onScreen = workspace.CurrentCamera:WorldToViewportPoint(v.Character[lockPart].Position)
            local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude

            if onScreen and distanceFromCenter <= fov then
                local magBuf = (v.Character[lockPart].Position - ray:ClosestPoint(v.Character[lockPart].Position)).Magnitude

                -- Verifica se o alvo está visível
                local ray = Ray.new(workspace.CurrentCamera.CFrame.Position, (v.Character[lockPart].Position - workspace.CurrentCamera.CFrame.Position).unit * 500)
                local part = workspace:FindPartOnRayWithIgnoreList(ray, {Players.LocalPlayer.Character, v.Character})
                if part == nil then
                    if magBuf < mag then
                        mag = magBuf
                        target = v
                    end
                end
            end
        end
    end

    return target
end

-- Atualiza a posição do círculo FOV
local function updateFOVRing()
    FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
end

-- Realça o alvo com um Highlight
local function highlightTarget(target)
    if highlightEnabled and target and target.Character then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = target.Character
        highlight.FillColor = Color3.fromRGB(255, 128, 128)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.Parent = target.Character
    end
end

-- Remove o Highlight do alvo
local function removeHighlight(target)
    if highlightEnabled and target and target.Character and target.Character:FindFirstChildOfClass("Highlight") then
        target.Character:FindFirstChildOfClass("Highlight"):Destroy()
    end
end

-- Prediz a posição do alvo com base na sua velocidade
local function predictPosition(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local velocity = target.Character.HumanoidRootPart.Velocity
        local position = target.Character[lockPart].Position
        local predictedPosition = position + (velocity * predictionFactor)
        return predictedPosition
    end
    return nil
end

-- Lida com a alternância do estado do aimbot e exibe notificação
local function handleToggle()
    if debounce then return end
    debounce = true
    toggleState = not toggleState
    
    StarterGui:SetCore("SendNotification", {
        Title = "Aimbot Status",
        Text = toggleState and "Aimbot Ativado" or "Aimbot Desativado",
        Duration = 3
    })
    
    wait(0.3)
    debounce = false
end

-- Função para atualizar a lista de jogadores e adicionar ESP
local function updatePlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            createESP(player)
        end
    end
end

-- Loop principal do aimbot
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        updateFOVRing()

        local cam = workspace.CurrentCamera

        if Toggle then
            if UserInputService:IsKeyDown(ToggleKey) then
                handleToggle()
            end
        else
            toggleState = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end

        if tick() - lastUpdate >= updateInterval then
            updatePlayers()
            lastUpdate = tick()
        end

        if toggleState then
            if not currentTarget then
                currentTarget = getClosest(cam.CFrame)
                highlightTarget(currentTarget)
            end

            if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(lockPart) then
                local predictedPosition = predictPosition(currentTarget)
                if predictedPosition then
                    workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(cam.CFrame.Position, predictedPosition), smoothing)
                end
                FOVring.Color = Color3.fromRGB(0, 255, 0)
            else
                FOVring.Color = Color3.fromRGB(255, 128, 128)
            end
        else
            if currentTarget then
                removeHighlight(currentTarget)
            end
            currentTarget = nil
            FOVring.Color = Color3.fromRGB(255, 128, 128)
        end
    end
end)

-- Chama a função updatePlayers uma vez ao iniciar o script para adicionar ESP aos jogadores já presentes
updatePlayers()

-- Adiciona um listener para adicionar ESP aos novos jogadores que entrarem no jogo
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Adiciona um listener para remover ESP dos jogadores que saírem do jogo
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)
