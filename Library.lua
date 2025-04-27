--[[
    Roblox Exploit UI Library
    Version: 1.0.0
    Author: YourNameHere
    Features:
    - Fully customizable UI system
    - Theme support (Dark, Light, and custom)
    - Window, Tab, and Section organization
    - Multiple UI elements (Buttons, Toggles, Sliders, etc.)
    - Notification system
    - Config saving/loading
--]]

local UILibrary = {
    Version = "1.0.0",
    Themes = {},
    Elements = {},
    CurrentTheme = "Dark",
    OpenWindows = {},
    Notifications = {},
    Dragging = nil,
    Resizing = nil,
    Utility = {}
}

-- Utility functions
function UILibrary.Utility:Create(class, properties)
    local instance = Drawing.new(class)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

function UILibrary.Utility:Round(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function UILibrary.Utility:RGBToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

function UILibrary.Utility:HexToRGB(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end

-- Theme system
UILibrary.Themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 40),
        Foreground = Color3.fromRGB(45, 45, 55),
        Accent = Color3.fromRGB(100, 150, 255),
        Text = Color3.fromRGB(240, 240, 240),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Shadow = Color3.fromRGB(10, 10, 20),
        Success = Color3.fromRGB(100, 255, 100),
        Warning = Color3.fromRGB(255, 200, 100),
        Error = Color3.fromRGB(255, 100, 100),
        Border = Color3.fromRGB(60, 60, 70)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 245),
        Foreground = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 100, 255),
        Text = Color3.fromRGB(40, 40, 40),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        Shadow = Color3.fromRGB(200, 200, 210),
        Success = Color3.fromRGB(0, 200, 0),
        Warning = Color3.fromRGB(255, 150, 0),
        Error = Color3.fromRGB(255, 50, 50),
        Border = Color3.fromRGB(200, 200, 210)
    },
    Custom = {}
}

function UILibrary:SetTheme(name)
    if self.Themes[name] then
        self.CurrentTheme = name
        for _, window in pairs(self.OpenWindows) do
            self:UpdateWindowTheme(window)
        end
    end
end

function UILibrary:CreateCustomTheme(name, colors)
    self.Themes[name] = colors
end

function UILibrary:UpdateWindowTheme(window)
    local theme = self.Themes[window.Config.Theme or self.CurrentTheme]
    if not theme then return end
    
    window.UI.Background.Color = theme.Background
    window.UI.Title.TextColor3 = theme.Text
    window.UI.Border.Color = theme.Border
    
    -- Update all elements in the window
    for _, tab in pairs(window.Tabs) do
        for _, section in pairs(tab.Sections) do
            for _, element in pairs(section.Elements) do
                if element.UpdateTheme then
                    element:UpdateTheme()
                end
            end
        end
    end
end

-- Window system
function UILibrary:CreateWindow(options)
    local config = {
        Title = options.Title or "UI Window",
        Size = options.Size or Vector2.new(400, 500),
        Position = options.Position or Vector2.new(100, 100),
        MinSize = options.MinSize or Vector2.new(300, 300),
        CanResize = options.CanResize ~= false,
        CanMinimize = options.CanMinimize ~= false,
        Theme = options.Theme or self.CurrentTheme,
        Icon = options.Icon or nil
    }
    
    local theme = self.Themes[config.Theme]
    
    local window = {
        Tabs = {},
        IsOpen = true,
        Config = config,
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(config.Size.X, config.Size.Y),
                Position = Vector2.new(config.Position.X, config.Position.Y),
                Color = theme.Background,
                Filled = true
            }),
            Border = self.Utility:Create("Square", {
                Size = Vector2.new(config.Size.X, config.Size.Y),
                Position = Vector2.new(config.Position.X, config.Position.Y),
                Color = theme.Border,
                Filled = false,
                Thickness = 1
            }),
            Title = self.Utility:Create("Text", {
                Text = config.Title,
                Size = 18,
                Position = Vector2.new(config.Position.X + 10, config.Position.Y + 8),
                Color = theme.Text,
                Outline = true,
                Center = false,
                Font = 2
            }),
            TabList = {},
            TabContent = {}
        }
    }
    
    -- Window dragging logic
    local mouse = game:GetService("UserInputService").GetMouseLocation(game:GetService("UserInputService"))
    local dragging = false
    local dragOffset = Vector2.new(0, 0)
    
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local titleBarRect = Rect.new(
                window.UI.Background.Position.X,
                window.UI.Background.Position.Y,
                window.UI.Background.Position.X + window.UI.Background.Size.X,
                window.UI.Background.Position.Y + 30
            )
            
            if titleBarRect:PointInRect(mousePos) then
                dragging = true
                dragOffset = mousePos - window.UI.Background.Position
                self.Dragging = window
            end
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if self.Dragging == window then
                self.Dragging = nil
            end
        end
    end
    
    game:GetService("UserInputService").InputBegan:Connect(onInputBegan)
    game:GetService("UserInputService").InputEnded:Connect(onInputEnded)
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging and self.Dragging == window then
            local mousePos = Vector2.new(game:GetService("UserInputService"):GetMouseLocation().X, game:GetService("UserInputService"):GetMouseLocation().Y)
            local newPos = mousePos - dragOffset
            
            window.UI.Background.Position = newPos
            window.UI.Border.Position = newPos
            window.UI.Title.Position = Vector2.new(newPos.X + 10, newPos.Y + 8)
            
            -- Update all other UI elements positions relative to the window
            for _, element in pairs(window.UI.TabList) do
                element.Position = Vector2.new(newPos.X + element.Offset.X, newPos.Y + element.Offset.Y)
            end
            
            for _, element in pairs(window.UI.TabContent) do
                element.Position = Vector2.new(newPos.X + element.Offset.X, newPos.Y + element.Offset.Y)
            end
        end
    end)
    
    table.insert(self.OpenWindows, window)
    return window
end

-- Tab system
function UILibrary:AddTab(window, options)
    local config = {
        Title = options.Title or "New Tab",
        Icon = options.Icon or nil
    }
    
    local theme = self.Themes[window.Config.Theme or self.CurrentTheme]
    
    local tab = {
        Sections = {},
        Config = config,
        ParentWindow = window,
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(80, 30),
                Position = Vector2.new(window.UI.Background.Position.X + (#window.Tabs * 80), window.UI.Background.Position.Y + 30),
                Color = theme.Foreground,
                Filled = true
            }),
            Text = self.Utility:Create("Text", {
                Text = config.Title,
                Size = 14,
                Position = Vector2.new(window.UI.Background.Position.X + (#window.Tabs * 80) + 10, window.UI.Background.Position.Y + 38),
                Color = theme.Text,
                Outline = true,
                Center = false,
                Font = 2
            })
        }
    }
    
    -- Store offsets for dragging
    tab.UI.Background.Offset = Vector2.new(#window.Tabs * 80, 30)
    tab.UI.Text.Offset = Vector2.new(#window.Tabs * 80 + 10, 38)
    
    table.insert(window.UI.TabList, tab.UI.Background)
    table.insert(window.UI.TabList, tab.UI.Text)
    
    table.insert(window.Tabs, tab)
    return tab
end

-- Section system
function UILibrary:AddSection(tab, options)
    local config = {
        Title = options.Title or "Section",
        Collapsible = options.Collapsible ~= false,
        DefaultState = options.DefaultState or "Expanded",
        Columns = options.Columns or 1,
        Padding = options.Padding or 10
    }
    
    local theme = self.Themes[tab.ParentWindow.Config.Theme or self.CurrentTheme]
    
    local sectionY = 70
    for _, section in pairs(tab.Sections) do
        sectionY = sectionY + section.UI.Background.Size.Y + 10
    end
    
    local section = {
        Elements = {},
        Config = config,
        ParentTab = tab,
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(tab.ParentWindow.Config.Size.X - 20, 40), -- Will expand with elements
                Position = Vector2.new(tab.ParentWindow.UI.Background.Position.X + 10, tab.ParentWindow.UI.Background.Position.Y + sectionY),
                Color = theme.Foreground,
                Filled = true
            }),
            Title = self.Utility:Create("Text", {
                Text = config.Title,
                Size = 16,
                Position = Vector2.new(tab.ParentWindow.UI.Background.Position.X + 20, tab.ParentWindow.UI.Background.Position.Y + sectionY + 10),
                Color = theme.Text,
                Outline = true,
                Center = false,
                Font = 2
            })
        }
    }
    
    -- Store offsets for dragging
    section.UI.Background.Offset = Vector2.new(10, sectionY)
    section.UI.Title.Offset = Vector2.new(20, sectionY + 10)
    
    table.insert(tab.ParentWindow.UI.TabContent, section.UI.Background)
    table.insert(tab.ParentWindow.UI.TabContent, section.UI.Title)
    
    table.insert(tab.Sections, section)
    return section
end

-- Button element
function UILibrary:AddButton(section, options)
    local config = {
        Text = options.Text or "Button",
        Callback = options.Callback or function() end,
        Tooltip = options.Tooltip or nil,
        Size = options.Size or UDim2.new(1, -20, 0, 30),
        Style = options.Style or "Default",
        Locked = options.Locked or false
    }
    
    local theme = self.Themes[section.ParentTab.ParentWindow.Config.Theme or self.CurrentTheme]
    
    local buttonY = 40
    for _, element in pairs(section.Elements) do
        buttonY = buttonY + element.UI.Background.Size.Y + 5
    end
    
    local button = {
        Config = config,
        ParentSection = section,
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(section.ParentTab.ParentWindow.Config.Size.X - 40, 30),
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + buttonY
                ),
                Color = theme.Accent,
                Filled = true
            }),
            Text = self.Utility:Create("Text", {
                Text = config.Text,
                Size = 14,
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20 + ((section.ParentTab.ParentWindow.Config.Size.X - 40) / 2),
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + buttonY + 8
                ),
                Color = theme.Text,
                Outline = true,
                Center = true,
                Font = 2
            })
        },
        
        SetLocked = function(self, state)
            self.Config.Locked = state
            self.UI.Background.Color = state and theme.TextSecondary or theme.Accent
        end,
        
        SetText = function(self, text)
            self.Config.Text = text
            self.UI.Text.Text = text
        end,
        
        UpdateTheme = function(self)
            local theme = UILibrary.Themes[self.ParentSection.ParentTab.ParentWindow.Config.Theme or UILibrary.CurrentTheme]
            self.UI.Background.Color = self.Config.Locked and theme.TextSecondary or theme.Accent
            self.UI.Text.Color = theme.Text
        end
    }
    
    -- Store offsets for dragging
    button.UI.Background.Offset = Vector2.new(20, section.UI.Background.Offset.Y + buttonY)
    button.UI.Text.Offset = Vector2.new(20 + ((section.ParentTab.ParentWindow.Config.Size.X - 40) / 2, section.UI.Background.Offset.Y + buttonY + 8)
    
    -- Button click logic
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not button.Config.Locked then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local buttonRect = Rect.new(
                button.UI.Background.Position.X,
                button.UI.Background.Position.Y,
                button.UI.Background.Position.X + button.UI.Background.Size.X,
                button.UI.Background.Position.Y + button.UI.Background.Size.Y
            )
            
            if buttonRect:PointInRect(mousePos) then
                -- Animate click
                button.UI.Background.Color = Color3.fromRGB(
                    math.floor(button.UI.Background.Color.R * 255 * 0.8),
                    math.floor(button.UI.Background.Color.G * 255 * 0.8),
                    math.floor(button.UI.Background.Color.B * 255 * 0.8)
                )
                
                task.spawn(function()
                    task.wait(0.1)
                    button.UI.Background.Color = theme.Accent
                    button.Config.Callback()
                end)
            end
        end
    end
    
    game:GetService("UserInputService").InputBegan:Connect(onInputBegan)
    
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, button.UI.Background)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, button.UI.Text)
    
    table.insert(section.Elements, button)
    return button
end

-- Toggle element
function UILibrary:AddToggle(section, options)
    local config = {
        Text = options.Text or "Toggle",
        Default = options.Default or false,
        Callback = options.Callback or function() end,
        Tooltip = options.Tooltip or nil,
        Style = options.Style or "Default"
    }
    
    local theme = self.Themes[section.ParentTab.ParentWindow.Config.Theme or self.CurrentTheme]
    
    local toggleY = 40
    for _, element in pairs(section.Elements) do
        toggleY = toggleY + element.UI.Background.Size.Y + 5
    end
    
    local toggle = {
        Value = config.Default,
        Config = config,
        ParentSection = section,
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(20, 20),
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + toggleY
                ),
                Color = config.Default and theme.Accent or theme.Foreground,
                Filled = true
            }),
            Border = self.Utility:Create("Square", {
                Size = Vector2.new(20, 20),
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + toggleY
                ),
                Color = theme.Border,
                Filled = false,
                Thickness = 1
            }),
            Text = self.Utility:Create("Text", {
                Text = config.Text,
                Size = 14,
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 50,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + toggleY + 3
                ),
                Color = theme.Text,
                Outline = true,
                Center = false,
                Font = 2
            })
        },
        
        SetState = function(self, state)
            self.Value = state
            self.UI.Background.Color = state and theme.Accent or theme.Foreground
            self.Config.Callback(state)
        end,
        
        Toggle = function(self)
            self:SetState(not self.Value)
        end,
        
        UpdateTheme = function(self)
            local theme = UILibrary.Themes[self.ParentSection.ParentTab.ParentWindow.Config.Theme or UILibrary.CurrentTheme]
            self.UI.Background.Color = self.Value and theme.Accent or theme.Foreground
            self.UI.Border.Color = theme.Border
            self.UI.Text.Color = theme.Text
        end
    }
    
    -- Store offsets for dragging
    toggle.UI.Background.Offset = Vector2.new(20, section.UI.Background.Offset.Y + toggleY)
    toggle.UI.Border.Offset = Vector2.new(20, section.UI.Background.Offset.Y + toggleY)
    toggle.UI.Text.Offset = Vector2.new(50, section.UI.Background.Offset.Y + toggleY + 3)
    
    -- Toggle click logic
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local toggleRect = Rect.new(
                toggle.UI.Background.Position.X,
                toggle.UI.Background.Position.Y,
                toggle.UI.Background.Position.X + toggle.UI.Background.Size.X,
                toggle.UI.Background.Position.Y + toggle.UI.Background.Size.Y
            )
            
            if toggleRect:PointInRect(mousePos) then
                toggle:Toggle()
            end
        end
    end
    
    game:GetService("UserInputService").InputBegan:Connect(onInputBegan)
    
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, toggle.UI.Background)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, toggle.UI.Border)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, toggle.UI.Text)
    
    table.insert(section.Elements, toggle)
    return toggle
end

-- Slider element
function UILibrary:AddSlider(section, options)
    local config = {
        Text = options.Text or "Slider",
        Min = options.Min or 0,
        Max = options.Max or 100,
        Default = options.Default or 50,
        Callback = options.Callback or function() end,
        Decimals = options.Decimals or 0,
        Suffix = options.Suffix or "",
        Tooltip = options.Tooltip or nil,
        FillMode = options.FillMode or "Static"
    }
    
    local theme = self.Themes[section.ParentTab.ParentWindow.Config.Theme or self.CurrentTheme]
    
    local sliderY = 40
    for _, element in pairs(section.Elements) do
        sliderY = sliderY + element.UI.Background.Size.Y + 5
    end
    
    local normalizedValue = (config.Default - config.Min) / (config.Max - config.Min)
    
    local slider = {
        Value = config.Default,
        Config = config,
        ParentSection = section,
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(section.ParentTab.ParentWindow.Config.Size.X - 40, 5),
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + sliderY + 20
                ),
                Color = theme.Foreground,
                Filled = true
            }),
            Fill = self.Utility:Create("Square", {
                Size = Vector2.new((section.ParentTab.ParentWindow.Config.Size.X - 40) * normalizedValue, 5),
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + sliderY + 20
                ),
                Color = theme.Accent,
                Filled = true
            }),
            Handle = self.Utility:Create("Circle", {
                Radius = 7,
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20 + ((section.ParentTab.ParentWindow.Config.Size.X - 40) * normalizedValue),
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + sliderY + 20 + 2.5
                ),
                Color = theme.Accent,
                Filled = true,
                Thickness = 1
            }),
            Text = self.Utility:Create("Text", {
                Text = config.Text,
                Size = 14,
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + sliderY
                ),
                Color = theme.Text,
                Outline = true,
                Center = false,
                Font = 2
            }),
            ValueText = self.Utility:Create("Text", {
                Text = tostring(config.Default) .. config.Suffix,
                Size = 14,
                Position = Vector2.new(
                    section.ParentTab.ParentWindow.UI.Background.Position.X + section.ParentTab.ParentWindow.Config.Size.X - 20,
                    section.ParentTab.ParentWindow.UI.Background.Position.Y + section.UI.Background.Offset.Y + sliderY
                ),
                Color = theme.TextSecondary,
                Outline = true,
                Center = false,
                Font = 2
            })
        },
        Dragging = false,
        
        SetValue = function(self, value)
            value = math.clamp(value, self.Config.Min, self.Config.Max)
            value = self.Utility:Round(value, self.Config.Decimals)
            self.Value = value
            
            local normalized = (value - self.Config.Min) / (self.Config.Max - self.Config.Min)
            self.UI.Fill.Size = Vector2.new((self.ParentSection.ParentTab.ParentWindow.Config.Size.X - 40) * normalized, 5)
            self.UI.Handle.Position = Vector2.new(
                self.ParentSection.ParentTab.ParentWindow.UI.Background.Position.X + 20 + ((self.ParentSection.ParentTab.ParentWindow.Config.Size.X - 40) * normalized),
                self.ParentSection.ParentTab.ParentWindow.UI.Background.Position.Y + self.ParentSection.UI.Background.Offset.Y + sliderY + 20 + 2.5
            )
            
            self.UI.ValueText.Text = tostring(value) .. self.Config.Suffix
            self.Config.Callback(value)
        end,
        
        UpdateTheme = function(self)
            local theme = UILibrary.Themes[self.ParentSection.ParentTab.ParentWindow.Config.Theme or UILibrary.CurrentTheme]
            self.UI.Background.Color = theme.Foreground
            self.UI.Fill.Color = theme.Accent
            self.UI.Handle.Color = theme.Accent
            self.UI.Text.Color = theme.Text
            self.UI.ValueText.Color = theme.TextSecondary
        end
    }
    
    -- Store offsets for dragging
    slider.UI.Background.Offset = Vector2.new(20, section.UI.Background.Offset.Y + sliderY + 20)
    slider.UI.Fill.Offset = Vector2.new(20, section.UI.Background.Offset.Y + sliderY + 20)
    slider.UI.Handle.Offset = Vector2.new(20 + ((section.ParentTab.ParentWindow.Config.Size.X - 40) * normalizedValue), section.UI.Background.Offset.Y + sliderY + 20 + 2.5)
    slider.UI.Text.Offset = Vector2.new(20, section.UI.Background.Offset.Y + sliderY)
    slider.UI.ValueText.Offset = Vector2.new(section.ParentTab.ParentWindow.Config.Size.X - 20, section.UI.Background.Offset.Y + sliderY)
    
    -- Slider dragging logic
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local sliderRect = Rect.new(
                slider.UI.Background.Position.X,
                slider.UI.Background.Position.Y - 10,
                slider.UI.Background.Position.X + slider.UI.Background.Size.X,
                slider.UI.Background.Position.Y + slider.UI.Background.Size.Y + 10
            )
            
            if sliderRect:PointInRect(mousePos) then
                slider.Dragging = true
                UILibrary.Dragging = slider
            end
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            slider.Dragging = false
            if UILibrary.Dragging == slider then
                UILibrary.Dragging = nil
            end
        end
    end
    
    game:GetService("UserInputService").InputBegan:Connect(onInputBegan)
    game:GetService("UserInputService").InputEnded:Connect(onInputEnded)
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if slider.Dragging and UILibrary.Dragging == slider then
            local mousePos = Vector2.new(game:GetService("UserInputService"):GetMouseLocation().X, game:GetService("UserInputService"):GetMouseLocation().Y)
            local relativeX = mousePos.X - (slider.ParentSection.ParentTab.ParentWindow.UI.Background.Position.X + 20)
            local normalized = math.clamp(relativeX / (slider.ParentSection.ParentTab.ParentWindow.Config.Size.X - 40), 0, 1)
            local value = slider.Config.Min + (slider.Config.Max - slider.Config.Min) * normalized
            slider:SetValue(value)
        end
    end)
    
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, slider.UI.Background)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, slider.UI.Fill)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, slider.UI.Handle)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, slider.UI.Text)
    table.insert(section.ParentTab.ParentWindow.UI.TabContent, slider.UI.ValueText)
    
    table.insert(section.Elements, slider)
    return slider
end

-- Notification system
function UILibrary:Notify(options)
    local config = {
        Title = options.Title or "Notification",
        Text = options.Text or "",
        Duration = options.Duration or 5,
        Type = options.Type or "Default",
        Sound = options.Sound or true
    }
    
    local theme = self.Themes[self.CurrentTheme]
    local accentColor
    
    if config.Type == "Success" then
        accentColor = theme.Success
    elseif config.Type == "Warning" then
        accentColor = theme.Warning
    elseif config.Type == "Error" then
        accentColor = theme.Error
    else
        accentColor = theme.Accent
    end
    
    local notification = {
        Config = config,
        Time = os.clock(),
        UI = {
            Background = self.Utility:Create("Square", {
                Size = Vector2.new(300, 80),
                Position = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X - 320,
                    20 + (#self.Notifications * 90)
                ),
                Color = theme.Foreground,
                Filled = true
            }),
            Accent = self.Utility:Create("Square", {
                Size = Vector2.new(5, 80),
                Position = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X - 320,
                    20 + (#self.Notifications * 90)
                ),
                Color = accentColor,
                Filled = true
            }),
            Title = self.Utility:Create("Text", {
                Text = config.Title,
                Size = 16,
                Position = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X - 310,
                    25 + (#self.Notifications * 90)
                ),
                Color = theme.Text,
                Outline = true,
                Center = false,
                Font = 2
            }),
            Text = self.Utility:Create("Text", {
                Text = config.Text,
                Size = 14,
                Position = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X - 310,
                    45 + (#self.Notifications * 90)
                ),
                Color = theme.TextSecondary,
                Outline = true,
                Center = false,
                Font = 2
            }),
            Progress = self.Utility:Create("Square", {
                Size = Vector2.new(300, 3),
                Position = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X - 320,
                    95 + (#self.Notifications * 90)
                ),
                Color = accentColor,
                Filled = true
            })
        }
    }
    
    table.insert(self.Notifications, notification)
    
    -- Notification lifetime
    task.spawn(function()
        local startTime = os.clock()
        while os.clock() - startTime < config.Duration do
            local elapsed = os.clock() - startTime
            local progress = 1 - (elapsed / config.Duration)
            notification.UI.Progress.Size = Vector2.new(300 * progress, 3)
            task.wait()
        end
        
        for _, element in pairs(notification.UI) do
            element:Remove()
        end
        
        for i, n in pairs(self.Notifications) do
            if n == notification then
                table.remove(self.Notifications, i)
                break
            end
        end
        
        -- Update positions of remaining notifications
        for i, n in pairs(self.Notifications) do
            local newY = 20 + ((i - 1) * 90)
            n.UI.Background.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 320, newY)
            n.UI.Accent.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 320, newY)
            n.UI.Title.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 310, newY + 5)
            n.UI.Text.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 310, newY + 25)
            n.UI.Progress.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X - 320, newY + 75)
        end
    end)
end

-- Example usage
local window = UILibrary:CreateWindow({
    Title = "Example UI",
    Size = Vector2.new(400, 500),
    Theme = "Dark"
})

local mainTab = UILibrary:AddTab(window, {
    Title = "Main",
    Icon = "⭐"
})

local combatSection = UILibrary:AddSection(mainTab, {
    Title = "Combat",
    Collapsible = true
})

UILibrary:AddButton(combatSection, {
    Text = "Kill All",
    Callback = function()
        UILibrary:Notify({
            Title = "Combat",
            Text = "Attempting to kill all players",
            Type = "Warning"
        })
    end
})

local aimbotToggle = UILibrary:AddToggle(combatSection, {
    Text = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        print("Aimbot:", state)
    end
})

local visualsSection = UILibrary:AddSection(mainTab, {
    Title = "Visuals",
    Collapsible = true
})

UILibrary:AddSlider(visualsSection, {
    Text = "Field of View",
    Min = 70,
    Max = 120,
    Default = 80,
    Suffix = "°",
    Callback = function(value)
        print("FOV set to:", value)
    end
})
