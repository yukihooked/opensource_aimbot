
local UserInputService = game:GetService("UserInputService") -- Gives Mouse Position / Gives us input
local RunService = game:GetService("RunService") -- Allows us to run things repetitively
local Players = game:GetService("Players") -- Gives us the Players and Characters

local local_player = Players.LocalPlayer

local cheat_client = {
    selected_hitbox = "Head",
    aim_key = Enum.KeyCode.LeftControl,
    fov = 100,
    smoothness = 4,

    teamkill = true,
    forcefield_check = true,
    invisible_check = true,
    invisible_threshold = .5,

    connections = {},
    drawings = {},
}

-- Cheat Functions
function cheat_client:get_camera()
    return workspace.CurrentCamera
end

function cheat_client:get_mouse_location()
    local mouse_location = UserInputService:GetMouseLocation()

    return Vector2.new(mouse_location.X, mouse_location.Y)
end

function cheat_client:calculate_target()
    local selected_target = nil
    local target_position = nil

    local minimum = math.huge

    local mouse_location = cheat_client:get_mouse_location()
    local player_list = Players:GetPlayers()
    for i = 1, #player_list do
        local player = player_list[i]
        local current_camera = cheat_client:get_camera()
        
        if player == local_player then -- Check if not self
            continue
        end

        if (player.Team == local_player.Team and not cheat_client.teamkill) then
            continue
        end
        
        if not player.Character then -- Checks if exists
            continue
        end

        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hitbox = character:FindFirstChild(cheat_client.selected_hitbox)
        
        if character:FindFirstChildOfClass("ForceField") and cheat_client.forcefield_check then
            continue
        end

        if not humanoid then -- Checks if Humanoid
            continue
        end

        if humanoid.Health <= 0 then -- Dead Check
            continue
        end

        if not hitbox then -- Checks if hitbox
            continue
        end

        if cheat_client.invisible_check and hitbox.Transparency >= cheat_client.invisible_threshold then
            continue
        end

        local screen_position, on_screen = current_camera:WorldToViewportPoint(hitbox.Position)
        if not on_screen then -- Check if onscreen
            continue
        end

        local delta = (Vector2.new(screen_position.X, screen_position.Y) - mouse_location).Magnitude
        if delta < minimum and delta <= cheat_client.fov then -- Check if they are closer than the last closest player and if they are within fov
            minimum = delta
            selected_target = player
            target_position = screen_position
        end
    end

    return selected_target, target_position
end

-- Utility
function cheat_client:create_drawing(drawing_class, drawing_properties)
    local drawing = Drawing.new(drawing_class)
    local properties = drawing_properties or {}

    for i,v in next, properties do
        drawing[i] = v
    end
    
    table.insert(self.drawings, drawing)
    return drawing
end

function cheat_client:create_connection(script_signal, callback)
    local proxy = {
        connection = script_signal:Connect(callback)
    }
    
    function proxy:disconnect()
        self.connection:Disconnect()

        table.clear(self)
        self = nil
    end

    table.insert(cheat_client.connections, proxy)
    return proxy
end

function cheat_client:unload()
    for _, connection_proxy in next, self.connections do
        connection_proxy:disconnect()
    end

    for i, drawing in next, self.drawings do
        drawing:Remove()
        self.drawings[i] = nil
        drawing = nil
    end

    table.clear(self)
    self = nil
end

local fov_circle = cheat_client:create_drawing("Circle", {
    Visible = true,
    Transparency = 1,
    Thickness = 1,
    Color = Color3.new(1,1,1),
    Radius =  cheat_client.fov,
})

cheat_client:create_connection(RunService.Heartbeat, function(delta_time)
    local mouse_location = cheat_client:get_mouse_location()

    fov_circle.Position = mouse_location

    if not UserInputService:IsKeyDown(cheat_client.aim_key) then
        return
    end

    local target, screen_position = cheat_client:calculate_target()
    if not target then
        return
    end

    local mouse_location = cheat_client:get_mouse_location()
    mousemoverel( (screen_position.X - mouse_location.X) / cheat_client.smoothness, (screen_position.Y - mouse_location.Y) / cheat_client.smoothness)
end)

-- Cheat Unloader
cheat_client:create_connection(UserInputService.InputBegan, function(input_object, processed)
    if processed then
        return
    end

    if input_object.KeyCode == Enum.KeyCode.End then
        cheat_client:unload()
    end
end)
