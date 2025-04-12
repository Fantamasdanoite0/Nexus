

local Nexus = {
    Version = "6.0",
    Logs = {},
    Methods = {"Direct", "Sandbox", "Coroutine", "Instance", "MetaHook"}
}

function Nexus:Log(message, color)
    color = color or Color3.fromRGB(255, 255, 255)
    table.insert(self.Logs, {text = message, color = color})

    if self.UI and self.UI.LogFrame then
        local LogLabel = Instance.new("TextLabel")
        LogLabel.Text = "> " .. message
        LogLabel.TextColor3 = color
        LogLabel.BackgroundTransparency = 1
        LogLabel.TextXAlignment = Enum.TextXAlignment.Left
        LogLabel.TextYAlignment = Enum.TextYAlignment.Top
        LogLabel.Font = Enum.Font.Code
        LogLabel.TextSize = 12
        LogLabel.Size = UDim2.new(1, -10, 0, 18)
        LogLabel.Parent = self.UI.LogFrame.List
        
        self.UI.LogFrame.List.CanvasSize = UDim2.new(0, 0, 0, #self.Logs * 18)
        self.UI.LogFrame.List.CanvasPosition = Vector2.new(0, self.UI.LogFrame.List.CanvasSize.Y.Offset)
    end
end

function Nexus:ExecuteScript(scriptSrc)
    if not scriptSrc or scriptSrc == "" then
        self:Log("ERRO: Nenhum script para executar", Color3.fromRGB(255, 50, 50))
        return false
    end

    local protectedScript = [[
        local _ENV = setmetatable({}, {
            __index = function(_, k) return getgenv()[k] end,
            __newindex = function(_, k, v) getgenv()[k] = v end
        })
        ]] .. scriptSrc

    for _, method in ipairs(self.Methods) do
        local success, result = pcall(function()
            return self["Execute_"..method](self, protectedScript)
        end)

        if success then
            self:Log("SUCESSO: Script executado ("..method..")", Color3.fromRGB(50, 255, 50))
            return true
        else
            self:Log("ERRO ("..method.."): "..tostring(result), Color3.fromRGB(255, 50, 50))
        end
    end
    
    return false
end

function Nexus:Execute_Direct(code)
    local fn, err = loadstring(code)
    if not fn then error(err) end
    return fn()
end

function Nexus:Execute_Sandbox(code)
    local env = setmetatable({}, {__index = getfenv()})
    local fn, err = loadstring(code)
    if not fn then error(err) end
    setfenv(fn, env)
    return fn()
end

function Nexus:Execute_Coroutine(code)
    local fn, err = loadstring(code)
    if not fn then error(err) end
    local co = coroutine.create(fn)
    local success, res = coroutine.resume(co)
    if not success then error(res) end
    return res
end

function Nexus:Execute_Instance(code)
    local container = Instance.new("Folder")
    container.Name = "PX_"..tostring(math.random(1, 1e6))
    
    local scriptObj = Instance.new("LocalScript")
    scriptObj.Source = code
    scriptObj.Parent = container
    
    local success, result = pcall(function()
        container.Parent = game:GetService("CoreGui")
        task.wait(0.1)
        container:Destroy()
    end)

    if not success then error(result) end
    return result
end

function Nexus:Execute_MetaHook(code)
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        if getnamecallmethod() == "Invoke" then
            loadstring(code)()
        end
        return old(self, ...)
    end
    
    game:GetService("TestService"):Invoke()
    setreadonly(mt, true)
    mt.__namecall = old
end

function Nexus:CreateUI()
    if self.UI then self.UI.Main:Destroy() end

    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NexusUI_"..tostring(math.random(1, 1e6))
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 450, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    TitleBar.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Text = "Nexus Ultimate v"..self.Version
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 1, 0)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CloseButton.Parent = TitleBar

    local Editor = Instance.new("TextBox")
    Editor.Size = UDim2.new(1, -20, 0.5, -10)
    Editor.Position = UDim2.new(0, 10, 0, 40)
    Editor.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Editor.TextColor3 = Color3.new(1, 1, 1)
    Editor.Text = "print('Hello Nexus Ultimate!')"
    Editor.MultiLine = true
    Editor.ClearTextOnFocus = false
    Editor.Font = Enum.Font.Code
    Editor.TextSize = 14
    Editor.Parent = MainFrame

    local ExecuteButton = Instance.new("TextButton")
    ExecuteButton.Size = UDim2.new(1, -20, 0, 35)
    ExecuteButton.Position = UDim2.new(0, 10, 0.52, 0)
    ExecuteButton.Text = "EXECUTAR (F5)"
    ExecuteButton.TextColor3 = Color3.new(1, 1, 1)
    ExecuteButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    ExecuteButton.Font = Enum.Font.GothamBold
    ExecuteButton.Parent = MainFrame

    local LogFrame = Instance.new("Frame")
    LogFrame.Size = UDim2.new(1, -20, 0.4, -10)
    LogFrame.Position = UDim2.new(0, 10, 0.6, 0)
    LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    LogFrame.Parent = MainFrame

    local LogList = Instance.new("ScrollingFrame")
    LogList.Size = UDim2.new(1, 0, 1, 0)
    LogList.BackgroundTransparency = 1
    LogList.ScrollBarThickness = 5
    LogList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogList.Parent = LogFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = LogList

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        self.UI = nil
    end)

    ExecuteButton.MouseButton1Click:Connect(function()
        self:ExecuteScript(Editor.Text)
    end)

    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F5 then
            self:ExecuteScript(Editor.Text)
        end
    end)

    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function()
        dragging = false
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    self.UI = {
        Main = ScreenGui,
        LogFrame = {
            Frame = LogFrame,
            List = LogList
        }
    }
end

function Nexus:Init()
    self:CreateUI()
    self:Log("Nexus Ultimate inicializado", Color3.fromRGB(100, 200, 255))
    self:Log("Pronto para executar scripts", Color3.fromRGB(150, 255, 150))
end

Nexus:Init()

getgenv().Nexus = {
    Execute = function(code)
        return Nexus:ExecuteScript(code)
    end,
    Version = Nexus.Version
}
