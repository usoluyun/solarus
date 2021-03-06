local petals = {
  {}, {}, {}, {}, {}
}
local remaining_petals = 5
local eye_sprite = nil
local arms_sprite = nil
local initial_xy = {}
local nb_sons_created = 0
local speed = 24
local timers = {}

function event_appear()

  sol.enemy.set_life(12)
  sol.enemy.set_damage(4)
  eye_sprite = sol.enemy.create_sprite("enemies/flora_gohma_eye")
  arms_sprite = sol.enemy.create_sprite("enemies/flora_gohma_eye")
  sol.enemy.set_size(104, 64)
  sol.enemy.set_origin(52, 64)
  sol.enemy.set_hurt_style("boss")
  sol.enemy.set_no_treasure()
  sol.enemy.set_push_hero_on_sword(true)
  sol.enemy.set_invincible()
  sol.enemy.set_attack_consequence("sword", "protected")
  sol.enemy.set_attack_consequence("boomerang", "protected")
  sol.enemy.set_attack_consequence("arrow", "protected")
  sol.enemy.set_attack_consequence_sprite(eye_sprite, "hookshot", "protected")

  -- create the petals
  for i = 1, 5 do
    petals[i].sprite = sol.enemy.create_sprite("enemies/flora_gohma_eye")
    petals[i].life = 3
    sol.enemy.set_attack_consequence_sprite(petals[i].sprite, "hookshot", "custom")
  end

  initial_xy.x, initial_xy.y = sol.enemy.get_position()

  -- go to the high layer
  sol.enemy.set_layer_independent_collisions(true)
  sol.enemy.set_position(initial_xy.x, initial_xy.y, 2)
end

function event_restart()

  eye_sprite:set_animation("eye")
  for i = 1, 5 do
    if petals[i].sprite ~= nil then
      petals[i].sprite:set_animation("petal_"..i)
    end
  end

  local m = sol.movement.create("target")
  m:set_speed(speed)
  m:set_target(initial_xy.x, initial_xy.y)
  sol.enemy.start_movement(m)
  for _, t in ipairs(timers) do t:stop() end

  repeat_create_son()
end

function event_update()

  local x, y = sol.enemy.get_position()
  local hero_x, hero_y = sol.map.hero_get_position()
  if hero_y < y - 60 and
      (petals[2].sprite ~= nil and hero_x <= x and hero_x > x - 32
      or petals[5].sprite ~= nil and hero_x >= x and hero_x < x + 32
      or petals[1].sprite ~= nil) then
    -- the top petals are too hard to reach: let the hookshot traverse
    -- the main sprite
    sol.enemy.set_attack_consequence_sprite(eye_sprite, "hookshot", "ignored")
  else
    sol.enemy.set_attack_consequence_sprite(eye_sprite, "hookshot", "protected")
  end
end

function event_custom_attack_received(attack, sprite)

  -- a petal was touched by the hookshot
  for i = 1, 5 do
    if petals[i].sprite == sprite
        and not string.find(sol.main.sprite_get_animation(petals[i].sprite),
	    "hurt") then
      petals[i].life = petals[i].life - 1
      sol.enemy.hurt(0)
      sol.audio.play_sound("enemy_hurt")
      petals[i].sprite:set_animation("petal_hurt_"..i)
      timers[#timers + 1] = sol.main:start_timer(300, function()

	if petals[i].life > 0 then
	  -- restore the petal animation
	  petals[i].sprite:set_animation("petal_"..i)
	else
	  -- destroy the petal
	  sol.audio.play_sound("stone")
	  sol.enemy.remove_sprite(petals[i].sprite)
	  petals[i].sprite = nil

	  remaining_petals = remaining_petals - 1
	  if remaining_petals <= 0 then
	    -- no more petals: make the eye vulnerable
	    speed = 48
	    sol.enemy.set_attack_consequence_sprite(eye_sprite, "sword", 1)
	    sol.enemy.restart()
	  end
	end

      end)
    end
  end
end

function event_movement_finished(movement)

  local m = sol.movement.create("random")
  m:set_speed(speed)
  m:set_max_distance(24)
  sol.enemy.start_movement(m)
end

function event_hurt(attack, life_lost)

  if sol.enemy.get_life() <= 0 then
    -- notify the body to make it stop moving
    sol.enemy.send_message(sol.enemy.get_father(), "dying")
    for _, t in ipairs(timers) do t:stop() end

    -- remove the sons
    for i = 1, nb_sons_created do
      local son_prefix = sol.enemy.get_name().."_son_"
      local son_name = son_prefix..i
      if not sol.map.enemy_is_dead(son_name) then
	sol.map.enemy_remove(son_name)
      end
    end
  end
end

function event_dead()

  -- notify the body
  sol.enemy.send_message(sol.enemy.get_father(), "dead")
end

function repeat_create_son()

  local son_prefix = sol.enemy.get_name().."_son_"
  if sol.map.enemy_get_group_count(son_prefix) < 10 then
    nb_sons_created = nb_sons_created + 1
    local son_name = son_prefix..nb_sons_created
    local _, _, layer = sol.map.enemy_get_position(sol.enemy.get_father())
    sol.enemy.create_son(son_name, "snap_dragon", 0, 0, layer)
    if math.random(2) == 1 then
      sol.map.enemy_set_treasure(son_name, "heart", 1, -1)
    end
  end

  timers[#timers + 1] = sol.main:start_timer(1000 + math.random(1000), repeat_create_son)
end

