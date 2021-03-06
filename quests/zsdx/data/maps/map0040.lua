-- Dungeon 3 1F

remove_water_delay = 500 -- delay between each step when some water is disappearing

-- Returns whether all five torches are on
function are_all_torches_on()

  return sol.map.npc_exists("torch_1")
      and sol.map.npc_get_sprite("torch_1"):get_animation() == "lit"
      and sol.map.npc_get_sprite("torch_2"):get_animation() == "lit"
      and sol.map.npc_get_sprite("torch_3"):get_animation() == "lit"
      and sol.map.npc_get_sprite("torch_4"):get_animation() == "lit" 
      and sol.map.npc_get_sprite("torch_5"):get_animation() == "lit" 
end

-- Makes all five torches on forever
function lock_torches()
  -- the trick: just remove the interactive torches because there are static ones below
  sol.map.npc_remove("torch_1")
  sol.map.npc_remove("torch_2")
  sol.map.npc_remove("torch_3")
  sol.map.npc_remove("torch_4")
  sol.map.npc_remove("torch_5")
end

-- Called when the map starts 
function event_map_started(destination_point_name)

  if sol.map.get_game():get_boolean(904) then
    -- the door before the five torches is open
    sol.map.switch_set_activated("ce_door_switch", true)
  end

  if sol.map.get_game():get_boolean(113) then
    -- the door after the five torches is open
    lock_torches()
  end

  if sol.map.get_game():get_boolean(121) then
    -- the water at the center is removed
    sol.map.tile_set_group_enabled("c_water", false)
    sol.map.tile_set_group_enabled("c_water_out", true)
    sol.map.jumper_set_group_enabled("c_water_on_jumper", false)
  else
    sol.map.obstacle_set_group_enabled("c_water_off_obstacle", false)
  end

  if sol.map.get_game():get_boolean(122) then
    -- the east water is removed
    sol.map.tile_set_group_enabled("e_water", false)
    sol.map.tile_set_group_enabled("e_water_out", true)
    sol.map.jumper_set_group_enabled("e_water_on_jumper", false)
  else
    sol.map.obstacle_set_group_enabled("e_water_off_obstacle", false)
  end

  if sol.map.get_game():get_boolean(131) then
    -- the north water is removed
    sol.map.tile_set_group_enabled("n_water", false)
    sol.map.tile_set_group_enabled("n_water_out", true)
    sol.map.jumper_set_group_enabled("n_water_on_jumper", false)
  else
    sol.map.obstacle_set_group_enabled("n_water_off_obstacle", false)
  end

end

-- Called when the opening transition of the map finished
function event_map_opening_transition_finished(destination_point_name)

  -- show the welcome message
  if destination_point_name == "from_outside" then
    sol.map.dialog_start("dungeon_3")
  end
end

function event_update()

  if not sol.map.get_game():get_boolean(113)
    and are_all_torches_on() then

    lock_torches()
    sol.map.camera_move(584, 360, 250, function()
      sol.audio.play_sound("secret")
      sol.map.door_open("torches_door")
    end)
  end
end

function event_switch_activated(switch_name)

  if switch_name == "se_door_switch" and not sol.map.door_is_open("se_door") then
    sol.map.camera_move(800, 728, 250, open_se_door)
  elseif switch_name == "ce_door_switch" and not sol.map.door_is_open("ce_door") then
    sol.map.camera_move(736, 552, 250, open_ce_door)
  elseif switch_name == "c_water_switch" and not sol.map.get_game():get_boolean(121) then
    sol.map.camera_move(344, 736, 250, remove_c_water, 1000, 3500)
  end
end

function open_se_door()
  sol.audio.play_sound("secret")
  sol.map.door_open("se_door")
end

function open_ce_door()
  sol.audio.play_sound("secret")
  sol.map.door_open("ce_door")
end

function remove_c_water()
  sol.audio.play_sound("water_drain_begin")
  sol.audio.play_sound("water_drain")
  sol.map.tile_set_enabled("c_water_out", true)
  sol.map.tile_set_enabled("c_water_source", false)
  sol.main:start_timer(remove_water_delay, remove_c_water_2)
end

function remove_c_water_2()
  sol.map.tile_set_enabled("c_water_middle", false)
  sol.main:start_timer(remove_water_delay, remove_c_water_3)
end

function remove_c_water_3()
  sol.map.tile_set_enabled("c_water", false)
  sol.map.tile_set_enabled("c_water_less_1", true)
  sol.main:start_timer(remove_water_delay, remove_c_water_4)
end

function remove_c_water_4()
  sol.map.tile_set_enabled("c_water_less_1", false)
  sol.map.tile_set_enabled("c_water_less_2", true)
  sol.main:start_timer(remove_water_delay, remove_c_water_5)
end

function remove_c_water_5()
  sol.map.tile_set_enabled("c_water_less_2", false)
  sol.map.tile_set_enabled("c_water_less_3", true)
  sol.main:start_timer(remove_water_delay, remove_c_water_6)
end

function remove_c_water_6()
  sol.map.tile_set_enabled("c_water_less_3", false)
  sol.map.jumper_set_group_enabled("c_water_on_jumper", false)
  sol.map.obstacle_set_group_enabled("c_water_off_obstacle", true)
  sol.map.get_game():set_boolean(121, true)
  sol.audio.play_sound("secret")
end

