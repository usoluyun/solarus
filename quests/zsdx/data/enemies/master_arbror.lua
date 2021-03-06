-- A giant tree boss from Newlink

local nb_sons_created = 0
local nb_sons_immobilized = 0
local nb_sons_immobilized_needed = 3 -- number of sons immobilized needed to get him vulnerable
local vulnerable = false
local initial_life = 8
local timers = {}

function event_appear()

  sol.enemy.set_life(initial_life)
  sol.enemy.set_damage(4)
  sol.enemy.create_sprite("enemies/master_arbror")
  sol.enemy.set_optimization_distance(0)
  sol.enemy.set_size(16, 16)
  sol.enemy.set_origin(8, 13)
  sol.enemy.set_pushed_back_when_hurt(false)
  sol.enemy.set_invincible()
  sol.enemy.set_attack_consequence("sword", "protected")
  sol.enemy.set_attack_consequence("arrow", "protected")
  sol.enemy.set_attack_consequence("boomerang", "protected")
  sol.enemy.set_attack_consequence("hookshot", "protected")
  sol.enemy.set_push_hero_on_sword(true)
  sol.enemy.set_can_hurt_hero_running(true)
end

function event_restart()

  local sprite = sol.enemy.get_sprite()
  if not vulnerable then
    go()
  else
    sprite:set_animation("vulnerable")
  end
end

function go()

  local m = sol.movement.create("random")
  m:set_speed(16)
  m:set_max_distance(16)
  sol.enemy.start_movement(m)
  for _, t in ipairs(timers) do t:stop() end
  timers[#timers + 1] = sol.main:start_timer(math.random(2000, 3000), prepare_son)
end

function event_hurt(attack, life_lost)

  local life = sol.enemy.get_life()
  if life <= 0 then
    local sprite = sol.enemy.get_sprite()
    sprite:set_ignore_suspend(true)
    sol.map.dialog_start("dungeon_3.arbror_killed")
    for _, t in ipairs(timers) do t:stop() end
    remove_sons()
  else
    if life > 9 then 
      nb_sons_immobilized_needed = 3
    elseif life > 7 then
      nb_sons_immobilized_needed = 4
    elseif life > 5 then
      nb_sons_immobilized_needed = 5
    else
      nb_sons_immobilized_needed = 6
    end
  end
end

function prepare_son()

  local sprite = sol.enemy.get_sprite()
  if not vulnerable and sprite:get_animation() == "walking" then
    son_prefix = sol.enemy.get_name() .. "_son"
    if sol.map.enemy_get_group_count(son_prefix) < nb_sons_immobilized_needed then
      local sprite = sol.enemy.get_sprite()
      sprite:set_animation("preparing_son")
      sol.audio.play_sound("hero_pushes")
      timers[#timers + 1] = sol.main:start_timer(1000, create_son)
      sol.enemy.stop_movement()
    end
  end

  timers[#timers + 1] = sol.main:start_timer(math.random(2000, 5000), prepare_son)
end

function create_son()

  x = math.random(-7, 7) * 16

  nb_sons_created = nb_sons_created + 1
  son_name = sol.enemy.get_name().."_son_"..nb_sons_created
  sol.enemy.create_son(son_name, "arbror_root", x, 80)
  local speed = 48 + (initial_life - sol.enemy.get_life()) * 5
  sol.enemy.send_message(son_name, speed)
  sol.audio.play_sound("stone")
end

function event_sprite_animation_finished(sprite, animation)

  if animation == "preparing_son" then
    sprite:set_animation("walking")
    sol.enemy.restart()
  elseif animation == "son_immobilized" then

    if nb_sons_immobilized >= nb_sons_immobilized_needed
        and not vulnerable then

      vulnerable = true
      sol.enemy.set_attack_consequence("sword", 1)
      sol.enemy.set_attack_consequence("arrow", 2)
      sol.enemy.stop_movement()
      sprite:set_animation("vulnerable")
      sol.audio.play_sound("boss_hurt")
      for _, t in ipairs(timers) do t:stop() end
      timers[#timers + 1] = sol.main:start_timer(4000, stop_vulnerable)
      remove_sons()
    else
      sprite:set_animation("walking")
    end
  end
end

function event_message_received(src_enemy, message)

  if message == "begin immobilized" then
    if nb_sons_immobilized < nb_sons_immobilized_needed then
      nb_sons_immobilized = nb_sons_immobilized + 1
      local sprite = sol.enemy.get_sprite()
      local animation = sprite:get_animation()

      if animation == "preparing_son" then
        sol.enemy.restart()
      end

      sprite:set_animation("son_immobilized")
    end

  elseif message == "end immobilized" then
    if nb_sons_immobilized > 0 then
      nb_sons_immobilized = nb_sons_immobilized - 1
    end
  end
end

function stop_vulnerable()

  vulnerable = false
  remove_sons()
  sol.enemy.set_invincible()
  sol.enemy.set_attack_consequence("sword", "protected")
  sol.enemy.set_attack_consequence("arrow", "protected")
  sol.enemy.set_attack_consequence("hookshot", "protected")
  sol.enemy.restart()
end

function remove_sons()
 
  local son_prefix = sol.enemy.get_name().."_son"
  --sol.map.enemy_remove_group(son_prefix) 
  nb_sons_immobilized = 0

  for i = 1, nb_sons_created do
    son = son_prefix.."_"..i
    if not sol.map.enemy_is_dead(son) then
      sol.enemy.send_message(son, "disappear")
    end
  end
end

