-- Dungeon 1 2F

fighting_miniboss = false

function event_map_started(destination_point_name)

  sol.map.chest_set_enabled("boss_key_chest", false)
  sol.map.door_set_open("stairs_door", true)
  sol.map.door_set_open("miniboss_door", true)
end

function event_map_opening_transition_finished(destination_point_name)

  -- show the welcome message
  if destination_point_name == "from_outside" then
    sol.map.dialog_start("dungeon_1")
  end
end

function event_hero_on_sensor(sensor_name)

  if sensor_name == "start_miniboss_sensor" and not sol.map.get_game():get_boolean(62) and not fighting_miniboss then
    -- the miniboss is alive
    sol.map.door_close("miniboss_door")
    sol.map.hero_freeze()
    sol.main:start_timer(1000, miniboss_timer)
    fighting_miniboss = true
  end
end

function miniboss_timer()
  sol.audio.play_music("boss")
  sol.map.enemy_set_enabled("khorneth", true)
  sol.map.hero_unfreeze()
end

function event_enemy_dead(enemy_name)

  if enemy_name == "khorneth" then
    sol.audio.play_music("light_world_dungeon")
    sol.map.door_open("miniboss_door")
  end

  if sol.map.enemy_is_group_dead("boss_key_battle")
      and not sol.map.chest_is_enabled("boss_key_chest") then
    sol.map.camera_move(104, 72, 250, boss_key_timer)
  end
end

function boss_key_timer()
  sol.audio.play_sound("chest_appears")
  sol.map.chest_set_enabled("boss_key_chest", true)
end

