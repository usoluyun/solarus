-- Dungeon 2 final room

function event_map_opening_transition_finished(destination_point_name)
  local solarus_child_sprite = sol.map.npc_get_sprite("solarus_child")
  sol.map.npc_set_position("solarus_child", 160, 165)
  solarus_child_sprite:set_animation("stopped")
  solarus_child_sprite:set_ignore_suspend(true)
end

function event_npc_interaction(npc_name)

  if npc_name == "solarus_child" then
    if sol.map.get_game():is_dungeon_finished(2) then
      -- dialog already done
      sol.audio.play_sound("warp")
      sol.map.hero_set_map(3, "from_dungeon_2", 1)
    else
      -- start the final sequence
      sol.map.camera_move(160, 120, 100, start_final_sequence)
    end
  end
end

function start_final_sequence()
  sol.map.dialog_start("dungeon_2.solarus_child")
  sol.map.dialog_set_variable("dungeon_2.solarus_child", sol.map.get_game():get_player_name());
end

function event_dialog_finished(dialog_id, answer)

  if dialog_id == "dungeon_2.solarus_child" then
    sol.map.hero_start_victory_sequence()
  end
end

function event_hero_victory_sequence_finished()
  sol.map.get_game():set_dungeon_finished(2)
  sol.map.hero_set_map(3, "from_dungeon_2", 1)
end

