local my_utility = require("my_utility/my_utility")

---- MENU
local menu_elements_whirl_wind_base = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash(my_utility.plugin_label .. "whirl_wind_base_main_bool")),
    use_as_filler_only = checkbox:new(true, get_hash(my_utility.plugin_label .. "use_as_filler_only_whirl_wind")),
    range_slider = slider_int:new(1, 9, 9, get_hash(my_utility.plugin_label .. "whirl_wind_range_slider")),
    fury_threshold = slider_int:new(0, 100, 30, get_hash(my_utility.plugin_label .. "fury_threshold")), -- Fury percentage threshold

    cast_at_target = checkbox:new(false, get_hash(my_utility.plugin_label .. "cast_at_target")), -- Cast at target position
    cast_at_cursor = checkbox:new(false, get_hash(my_utility.plugin_label .. "cast_at_cursor")), -- Cast at cursor position
}

local function menu()
    if menu_elements_whirl_wind_base.tree_tab:push("whirl_wind") then
        menu_elements_whirl_wind_base.main_boolean:render("Enable Spell", "")
        if menu_elements_whirl_wind_base.main_boolean:get() then
            menu_elements_whirl_wind_base.range_slider:render("Spell Range", "Set the range for WW check enemy to cast")
            menu_elements_whirl_wind_base.fury_threshold:render("Fury Check (%)", "Fury level to maintain channeling")
            
            -- Add new checkboxes for casting at target or cursor position
            menu_elements_whirl_wind_base.cast_at_target:render("Cast at Target Position", "Cast Whirlwind at the enemy target's position")
            menu_elements_whirl_wind_base.cast_at_cursor:render("Cast at Cursor Position", "Cast Whirlwind at the cursor position")
        end
        menu_elements_whirl_wind_base.tree_tab:pop()
    end
end

-- OTHERS
local spell_id_whirl_wind = 206435
local next_time_allowed_cast = 0.0

-- Main logic function
local function logics(target)
    -- Check if the spell can be cast
    local menu_boolean = menu_elements_whirl_wind_base.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id_whirl_wind)

    if not is_logic_allowed then
        return false
    end

        local player_local = get_local_player()

        local current_resource_ws = player_local:get_primary_resource_current()
        local max_resource_ws = player_local:get_primary_resource_max()
        local fury_perc = (current_resource_ws / max_resource_ws) * 100
        local fury_threshold = menu_elements_whirl_wind_base.fury_threshold:get()

        if fury_perc < fury_threshold then
            return false
        end
   

    local enemies = actors_manager.get_enemy_npcs()
    local spell_range = menu_elements_whirl_wind_base.range_slider:get()
    local player_position = get_player_position()
    local is_wall_collision = target_selector.is_wall_collision(player_position, target, 1.20)
    if is_wall_collision then
        return false
    end

    for i, enemy in ipairs(enemies) do
        local dist = player_position:dist_to(enemy:get_position())
        if dist < spell_range then
            -- Get the selected casting mode
            local cast_at_target = menu_elements_whirl_wind_base.cast_at_target:get()
            local cast_at_cursor = menu_elements_whirl_wind_base.cast_at_cursor:get()
            
            -- Cast based on the selected option
            if cast_at_target then
                local target_position = enemy:get_position() -- Get the target's position
                if cast_spell.position(spell_id_whirl_wind, target_position, 1) then
                    --console.print("Casted Whirlwind at target position.")
                    next_time_allowed_cast = get_time_since_inject()
                    return true
                end
            elseif cast_at_cursor then
                local cursor_position = get_cursor_position() -- Get the cursor's position
                if cast_spell.position(spell_id_whirl_wind, cursor_position, 1) then
                    --console.print("Casted Whirlwind at cursor position.")
                    next_time_allowed_cast = get_time_since_inject()
                    return true
                end
            end
        end
    end

    return false
end

return {
    menu = menu,
    logics = logics,
}