pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- j46k
-- by dfire

--[[const]] debug = 0

--[[const]] jonny_cash_enabled = 0
--[[const]] spidys_to_beat_boss = 50

--[[const]] mapsize = 48
--[[const]] startx = 1
--[[const]] starty = 1
--[[const]] wall=7
--[[const]] floor=9
--[[const]] sfx_enabled=0

-- spawn chances
--   note: adding too many assests will cause lag
--[[const]] lady_spawn_number = 1
--[[const]] spidy_spawn_number = 5
--[[const]] tsnow_spawn_number = 8
--[[const]] aibit_spawn_number = 3

-- sprites
--[[const]] tsnow_sprite = 32
--[[const]] lady_sprite = 48
--[[const]] spidy_sprite = 36
--[[const]] aibit_sprite = 20
--[[const]] portal_sprite = 10
--[[const]] trs80_sprite = 24

-- actor ids:
--[[const]] player_id = 0
--[[const]] lady_id = 1
--[[const]] tsnow_id = 2
--[[const]] aibit_id = 3
--[[const]] spidy_id = 4
--[[const]] trs80_id = 5

-- how many aibits till we can get to the boss
--[[const]] ai_bits_til_boss = 20

--[[const]] lady_attack_modifier = 20
--[[const]] launch_speed = 1.8
--[[const]] lady_inertia = .8
--[[const]] lady_inertia_cap = 1
--[[const]] lady_inertia_inc = 0--.08
--[[const]] lady_bounce = 1
--[[const]] lady_speed = 1
--[[const]] lady_return_rate = .2

--[[const]] spidy_follow_rate = .03
--[[const]] spidy_aggro_distance = 15

--[[const]] jon_sprite = 0
--[[const]] jon_attack_modifier = 1
--[[const]] thunder_power_attack_modifier = 1

-- how fast to accelerate
--[[const]] jon_accel_rate = 0.1
--[[const]] jon_accel = 0.125
--[[const]] thunder_snow_accel_multiplier = 40
--[[const]] jon_initial_speed = .08
--[[const]] jon_accel_upper_limit = .15

-- tsnow_increment is how much
--  it will increase jon's thunderpower
--[[const]] tsnow_increment = 10
--[[const]] spidy_health = 100

--[[const]] left = 0
--[[const]] left_up = 1
--[[const]] left_down = 2
--[[const]] right = 3
--[[const]] right_up = 4
--[[const]] right_down = 5
--[[const]] up = 6
--[[const]] down = 7

-- game_states:
--[[const]] setup_intro_level = 0
--[[const]] play_intro_level = 1
--[[const]] setup_open_level = 2
--[[const]] play_open_level = 3
--[[const]] setup_trs80_level = 4
--[[const]] play_trs80_level = 5
--[[const]] setup_boss_fight = 6
--[[const]] play_boss_fight = 7
--[[const]] setup_game_over = 8
--[[const]] game_over_state = 9

-- game state:
game_state = setup_intro_level

music(0)
cam_x = 0
cam_y = 0

last = 0
msg_color = 1

--[[const]] line_char_count = 24

-- clear the log
printh("", "log", true)

-- logs to a file called log.p8l
--   only if debug is not set to zero
function log(str)
  if(debug == 0) return

  printh(str, "log")
end

function check_for_message()
  if flr(time()) - last == 2 then
    gmsg = nil
  end

  if (gmsg != nil) then
    rectfill(0, 100, 128, 110, 0)
    print(gmsg, 10, 102, msg_color)
  end
end

function message(msg)
    last = flr(time())
    msg_color = (msg_color + 1) % 15 + 1
    gmsg = msg
end

function advance_game_state()
  reset_colors()
  delete_all_actors()
  game_state += 1
  log("update state -- game_state: "..game_state)
end

player_initialized = 0

function _update()
-- deal with all windows before moving on with the game
  if #windows > 0 then
    handle_window(windows[1])
    return
  end

  init_player()

  if(game_state == setup_intro_level) then
    advance_game_state()
    init_intro_level()
  elseif (game_state == play_intro_level) then
    if(jon.x > 13 and jon.y < 3) then
      advance_game_state()
      explain_aibits = make_window()
      explain_aibits.message = "collect aibits to power your super computer"

      explain_tsnow = make_window()
      explain_tsnow.message = "collect thundersnow to boost your attack power and speed!"
    end
    standard_update()
  elseif (game_state == setup_open_level) then
    advance_game_state()
    init_open_level()
  elseif (game_state == play_open_level) then
    if (alt_open_level == 1) pal(13, 5)
    standard_update()
  elseif (game_state == play_open_level+1) then
    if (jon.aibits < ai_bits_til_boss) then
      game_state = setup_open_level
    else
      advance_game_state()
      init_trs80_level()
    end
  elseif (game_state == play_trs80_level) then
    standard_update()
  elseif (game_state == setup_boss_fight) then
    advance_game_state()
    init_boss_fight()
  elseif (game_state == play_boss_fight) then
    standard_update()
    update_boss_fight()
  elseif (game_state == setup_game_over) then
    advance_game_state()
    init_game_over()
  elseif (game_state == game_over_state) then
  end
end

function _draw()
  cls()

  if(game_state == play_intro_level) then
    camera(0, 0)

    map(0, 0, 0, 0, 16, 16)
  elseif (game_state == play_trs80_level) then
    camera(0, 0)

    map(0, 0, 0, 0, 16, 16)
  elseif (game_state == play_open_level) then
    camera(cam_x^1.5, cam_y^1.5)

    map(0, 0, 0, 0, 128, 128)
  elseif (game_state == play_boss_fight) then
    camera(0, 0)

    map(0, 0, 0, 0, 16, 16)
  elseif (game_state == game_over_state) then
    print("game over - press start",15,64, msg_color)
    draw_windows()
    if (time() % 4 == 0) then
      message()
      check_for_message()
      pal(11, msg_color)
    end
    return
  end

  -- draw actors
  foreach(actor,draw_actor)
  draw_actor(jon)

  camera() -- resets camera postion to static so we can draw game info
  print_debug()
  draw_game_info()
  check_for_message()
  draw_windows()
  if(time() - last_hit > .2 and time() - last_pickup > .2) reset_colors()
end

function print_debug()
  if (debug == 0) return
  -- log jon's coordinates
  print("x "..jon.x,0,120,7)
  print("y "..jon.y,64,120,7)
  print('('..cam_x..', '..cam_y..')', 0, 0, 7)
end

function standard_update()
  control_player(jon)
  update_player()
  move_actor(jon)
  foreach(actor, move_actor)

  if (jon.aibits >= ai_bits_til_boss) unlock_trs80()
end

function init_boss_fight()
  mapsize = 15
end

function update_boss_fight()
  if (time() % 2 == 0) insert_actor(spidy_id)

  if (spidys_killed_boss_fight > spidys_to_beat_boss) then
    advance_game_state()
  end
end

function init_game_over()
    delete_all_actors()
    music(20)
    game_over = make_window()
    spidy_stats = make_window()
    tsnow_stats = make_window()
    lady_stats = make_window()
    cash_stats = make_window()
    shameless_plug = make_window()

    game_over.message = "        game over."
    spidy_stats.message = " total spidys killed: "..spidys_killed+spidys_killed_boss_fight
    cash_stats.message = " cash earned: $"..jon.cash
    tsnow_stats.message = " thundersnow consumed: "..total_tsnow_collected
    lady_stats.message = " strippers befriended: "..jon.bandolier
    shameless_plug.message = " thanks for playing!!!  code can be found here: github.com/  dfirebaugh/j46k"
end

function init_intro_level()
  starting_window = make_window()
  starting_window.message = "Jon, you hate spiders.  Good thing these nice strippers have agreed to help you."

  draw_small_room()
  place_lady(5, 5)
  place_lady(5, 10)
  place_lady(2, 5)
  place_tsnow(5, 8)
  place_tsnow(5, 10)
  place_tsnow(5, 11)
  place_spidy(10, 12)
  mset(14, 1, portal_sprite)
end

alt_open_level = 0
function init_open_level()
  alt_open_level = alt_open_level == 1 and 0 or 1
  -- draw a room
  for i = 0, mapsize do
    for j = 0, mapsize do
      mset(i, j, floor)
    end
    mset(i, 0, wall)
    mset(0, i, wall)
  end
  for i = 0, mapsize do
    mset(i, 0, wall)
    mset(0, i, wall)
    mset(mapsize, i, wall)
    mset(i, mapsize, wall)
  end

  for i = 0, 200 do
    mset(rnd(mapsize) + 1, rnd(mapsize) + 1, wall)
  end

  -- giv the player some room
  mset(1, 1, floor)
  mset(1, 2, floor)
  mset(1, 3, floor)
  mset(2, 1, floor)
  mset(2, 2, floor)
  mset(2, 3, floor)

  reset_player()
  init_actors()

  insert_portal()
end

function init_trs80_level()
  reset_player()
  draw_small_room()
  place_trs80()
end

function draw_small_room()
  -- draw a room
  for i = 0, 14 do
    for j = 0, 14 do
      mset(i, j, floor)
    end
    mset(i, 0, wall)
    mset(0, i, wall)
    mset(15, i, wall)
    mset(i, 13, wall)
  end
  mset(15,15, wall)
end

function draw_game_info()
  rectfill(0, 110, 128, 128, 0)
  check_for_message()

  -- left side
  print("thunder: "..jon.thunder_power, 10, 122, 10)
  print("ai_bits: "..jon.aibits, 10, 112, 10)

  -- right side
  print("cash: "..jon.cash, 65, 122, 10)
  print("bandolier: "..jon.bandolier, 65, 112, 10)
end

function reset_colors()
  pal(1, 1)
  pal(2, 2)
  pal(3, 3)
  pal(4, 4)
  pal(5, 5)
  pal(6, 6)
  pal(7, 7)
  pal(8, 8)
  pal(9, 9)
  pal(10, 10)
  pal(11, 11)
  pal(12, 12)
  pal(13, 13)
  pal(14, 14)
  pal(15, 15)
end

function unlock_trs80()
  if (trs80_unlocked != 1) then
    local w = make_window()
    w.message = "you've unlocked the trs80.  find a portal to get to the trs80"
  end
  trs80_unlocked = 1
end

function place_trs80()
  if (trs80_placed == 1) return

  trs80_placed = 1
  trs80 = make_actor(6, 6)
  trs80.spritesize = 4
  trs80.spr = trs80_sprite
  trs80.name = "trs80"
  trs80.actor_id = trs80_id
end

-->8
-- actor
actor = {} --all actors in world

-- inserts actor to the map
-- if the cell is already occupied, we try again
function insert_actor(actor_type)
  local rndx = flr(rnd(mapsize) + 1)
  local rndy = flr(rnd(mapsize) + 1)

  if (mget(rndx, rndy) == floor and is_within_map(rndx, rndy)) then
    place_actor(rndx, rndy, actor_type)
    return
  end

  insert_actor(actor_type)
end

-- if the randomly selected tile is not a floor tile, 
--   we will call the function again
function insert_portal()
  local rndx = flr(rnd(mapsize) + 1)
  local rndy = flr(rnd(mapsize) + 1)

  if (mget(rndx, rndy) != floor) insert_portal()

  log("set portal: x:"..rndx.." y: "..rndy)

  mset(rndx, rndy, portal_sprite)
end

-- init_actors
-- initializes starting actors
function init_actors()
  -- iterate through the map and place actors
  for i = 1, spidy_spawn_number do
    insert_actor(spidy_id)
  end

  for i = 1, aibit_spawn_number do
    insert_actor(aibit_id)
  end

  for i = 1, tsnow_spawn_number do
    insert_actor(tsnow_id)
  end

  for i = 1, lady_spawn_number do
    insert_actor(lady_id)
  end
end

function place_actor(x, y, actor_type)
  log("palced an actor: "..actor_type.." x: "..x.." y: "..y)

  if (actor_type == spidy_id) place_spidy(x,y)

  if (actor_type == aibit_id) place_aibit(x, y)

  if (actor_type == tsnow_id) place_tsnow(x, y)

  if (actor_type == lady_id) place_lady(x, y)

end

-- make an actor
-- and add to global collection
-- x,y means center of the actor
-- in map tiles (not pixels)
function make_actor(x, y)
  a={}
  a.x = x
  a.y = y
  a.spritesize = 1
  a.dx=1
  a.dy=-0.1
  a.inertia=0.5
  a.spr = 16
  a.frame = 0
  a.t = 0
  a.bounce  = 1
  a.frames=2

  -- half-width and half-height
  -- slightly less than 0.5 so
  -- that will fit through 1-wide
  -- holes.
  a.w = 0.4
  a.h = 0.4
  
  add(actor,a)

  return a
end

function move_lady(a)
  if (jon.x > a.x) then
    a.x += lady_return_rate
  end
  if (jon.x < a.x) then
    a.x -= lady_return_rate
  end
  if (jon.y > a.y) then
    a.y += lady_return_rate
  end
  if (jon.y < a.y) then
    a.y -= lady_return_rate
  end
end

function move_spidy(a)
  if(abs(jon.x - a.x) < spidy_aggro_distance and 
     abs(jon.y - a.y) < spidy_aggro_distance) then

    if (jon.x > a.x) then
      a.dx = spidy_follow_rate
    end
    if (jon.x < a.x) then
      a.dx = -spidy_follow_rate
    end
    if (jon.y > a.y) then
      a.dy = spidy_follow_rate
    end
    if (jon.y < a.y) then
      a.dy = -spidy_follow_rate
    end
  else -- move spidy a bit back and forth
    a.dx += flr(time())%6 < 3  and spidy_follow_rate or -spidy_follow_rate
  end
end

function animate_actor(a)
  a.frame_inc += .5
  a.frame_inc %= 1
  a.frame += a.frame_inc
  a.frame %= a.frames

  a.t += 1
end

function move_actor(a)

  -- if it's a lady 
  --   move toward jon
  if (a.actor_id == lady_id) move_lady(a)

  if (a.actor_id == tsnow_id) animate_actor(a)

  -- only move actor along x
  -- if the resulting position
  -- will not overlap with a wall
  if not solid_a(a, a.dx, 0) then
    a.x += a.dx
  else
    -- otherwise bounce
    a.dx *= -a.bounce
    if (sfx_enabled == 1) sfx(9)
  end

    -- ditto for y
  if not solid_a(a, 0, a.dy) then
    a.y += a.dy
  else
    a.dy *= -a.bounce
    if (sfx_enabled == 1) sfx(9)
  end


  -- apply inertia
  -- set dx,dy to zero if you
  -- don't want inertia
  a.dx *= a.inertia
  a.dy *= a.inertia

  -- advance one frame every
  -- time actor moves 1/4 of
  -- a tile
  
  a.frame += abs(a.dx) * 4
  a.frame += abs(a.dy) * 4
  a.frame %= a.frames

  a.t += 1

  -- if it's a spidy
  --   move the spidy
  -- note: this happens after collisions
  if (a.actor_id == spidy_id) move_spidy(a)
end

function make_lady(x, y)
  local l = {}
  l.x = x
  l.y = y
  l.spritesize = 1
  l.frame = 0
  l.t = 0

  l.w = 0.4
  l.h = 0.4
  
  l.spr = 48
  l.name = "lady"
  l.inertia = lady_inertia
  l.bounce = lady_bounce
  l.frames = 3
  l.dx = lady_speed
  l.dy = lady_speed
  l.actor_id = lady_id
  return l
end

function place_lady(x, y)
  local lady = make_lady(x, y)
  
  add(actor,lady)
end

function place_spidy(x, y)
  spidy = make_actor(x, y)
  spidy.spritesize = 2
  spidy.spr = spidy_sprite
  spidy.name = "spidy"
  spidy.health = spidy_health
  spidy.actor_id = spidy_id
end

function place_aibit(x, y)
  aibit = make_actor(x, y)
  aibit.spr = aibit_sprite
  aibit.actor_id = aibit_id
end

function place_tsnow(x, y)
  tsnow = make_actor(x, y)
  tsnow.spr = tsnow_sprite
  tsnow.actor_id = tsnow_id
  tsnow.frames = 3
  tsnow.frame_inc = 0
end

function is_attacker(x, y)
  val=mget(x, y)

  -- check if flag 3 is set (the
  -- green toggle button in the 
  -- sprite editor)
  return fget(val, 3)
end


-- for any given point on the
-- map, true if it is tsnow
-- there.
function is_tsnow(x, y)
  -- grab the cell value
  val=mget(x, y)

  -- check if flag 2 is set (the
  -- orange toggle button in the 
  -- sprite editor)
  return fget(val, 2)
end

-- has_tsnow
-- check if a rectangle has a 
-- tsnow tile
function has_tsnow(x,y,w,h)

  return 
    is_tsnow(x-w,y-h) or
    is_tsnow(x+w,y-h) or
    is_tsnow(x-w,y+h) or
    is_tsnow(x+w,y+h)
end

-- for any given point on the
-- map, true if there is wall
-- there.
function solid(x, y)
  -- grab the cell value
  val=mget(x, y)

  -- check if flag 1 is set (the
  -- orange toggle button in the 
  -- sprite editor)
  return fget(val, 1)
end

-- solid_area
-- check if a rectangle overlaps
-- with any walls
-- 
--(this version only works for
--actors less than one tile big)
function solid_area(x,y,w,h)

  return 
    solid(x-w,y-h) or
    solid(x+w,y-h) or
    solid(x-w,y+h) or
    solid(x+w,y+h)
end

function delete_all_actors()
  actor={}
end

function delete_actor(a)
  for i=1, #actor do
    if (actor[i].x == a.x and actor[i].y == a.y and actor[i].actor_id == a.actor_id) then
      del(actor, actor[i])
      return
    end
  end
end

last_hit = 0
function handle_enemy_collide()
  last_hit = flr(time())
  pal(13, 8)
  pal(6, 0)
end

last_pickup=0
function handle_item_pickup()
  last_pickup = time()
  -- pal(6, 7)
  pal(15, 7)
end


function handle_trs80_collision(a, trs80_actor)
function deletetrs80()
  delete_actor(trs80_actor)
  music(12)
  advance_game_state()
end

  if(trs80_actor.actor_id == trs80_id) then
    if (a.player or a.actor_id == lady_id) then
      w = make_window()
      w.message = "welcome jon.  deposite aibits to start building your ai super power. Press btn to deposit aibits"
      w1 = make_window()
      w1.message = "cpu overloading... aibits generating supercomputer super nodes"
      w.callback = deletetrs80
    end
  end
end

function handle_ai_bit_collision(a, aibit_actor)
  if(aibit_actor.actor_id == aibit_id) then
    delete_actor(aibit_actor)
    if (a.player or a.actor_id == lady_id) then
      if jon.aibits == ai_bits_til_boss - 1 then
        sfx(57)
      else
        sfx(60)
      end
      handle_item_pickup()
      jon.aibits += 1
      message("picked up aibit")
    end
  end
end

function handle_tsnow_collision(a, a2)
    -- if actor collides with some thunder snow
    if(a2.actor_id == tsnow_id) then
      if (a.player  or a.actor_id == lady_id) then
        sfx(59)
        handle_item_pickup()
        -- cap thunderpower at 100
        jon.thunder_power = (jon.thunder_power+tsnow_increment > 100) and 
          100 or (jon.thunder_power + 10)
        jon.cash -= 10

        total_tsnow_collected += 1
        message("picked up some thunder snow!")
      end

      delete_actor(a2)
    end
end

function handle_spidy_collision(a, spidy)
  if(spidy.actor_id == spidy_id) then
      -- if actor happens to be a lady
      if (a.actor_id == lady_id) then
        -- reduce spidy's health
        spidy.health -= lady_attack_modifier
      end

      if (a.player) then
          sfx(58)
        handle_enemy_collide()
        spidy.health -= jon_attack_modifier + (jon.thunder_power + thunder_power_attack_modifier)
        message(jon_attack_modifier + (jon.thunder_power + thunder_power_attack_modifier).." dmg to spidy. lost: aibit")
        if (jon.aibits > 0) then
          jon.aibits -= 1
          jon.thunder_power -= 10
          if (jon.thunder_power < 0) then
            jon.thunder_power = 0
          end
        end
      end

      if (spidy.health < 0) then

        count_spidy()

        local drop_rnd = rnd(100) + 1

        if (drop_rnd < 75) then
          if (game_state > setup_boss_fight) then
            place_tsnow(spidy.x, spidy.y)
            message("spidy dropped a thundersnow")
          elseif (jon.aibits < ai_bits_til_boss) then
            place_aibit(spidy.x, spidy.y)
            message("spidy dropped an aibit")
          else
            place_tsnow(spidy.x, spidy.y)
            message("spidy dropped a thundersnow")
          end
        elseif (drop_rnd >= 75 and drop_rnd < 85) then
          place_lady(spidy.x, spidy.y)
          message("spidy dropped a stripper")
        else
          place_tsnow(spidy.x, spidy.y)
          message("spidy dropped a thundersnow")
        end
        delete_actor(spidy)
      end
  end
end

function track_with_player(a)
  if(a.track_jon) then
    a.x = jon.x
    a.y = jon.y
  end
end


last_btn = 1
function launch_actor()
  if(jon.bandolier > 0) then
    sfx(62)
    jon.bandolier -= 1
    local launched_actor = make_lady(jon.x, jon.y)
    add(actor, launched_actor)
    launched_actor.dx = 0
    launched_actor.dy = 0

    if (last_btn == left) then
      launched_actor.dx -= launch_speed
    elseif (last_btn == right) then
      launched_actor.dx += launch_speed
    elseif (last_btn == up) then
      launched_actor.dy -= launch_speed
    elseif (last_btn == down) then
      launched_actor.dy += launch_speed
    elseif (last_btn == left_up) then
      launched_actor.dx -= launch_speed
      launched_actor.dy -= launch_speed
    elseif (last_btn == left_down) then
      launched_actor.dx -= launch_speed
      launched_actor.dy += launch_speed
    elseif (last_btn == right_up) then
      launched_actor.dx += launch_speed
      launched_actor.dy -= launch_speed
    elseif (last_btn == right_down) then
      launched_actor.dx += launch_speed
      launched_actor.dy += launch_speed
    end
  end
end

function multi_dir_attack()
    if (jon.bandolier > 0) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dx -= launch_speed
    end
    if (jon.bandolier > 1) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dx += launch_speed
    end
    if (jon.bandolier > 2) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dy -= launch_speed
    end
    if (jon.bandolier > 3) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dy += launch_speed
    end
    if (jon.bandolier > 4) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dx -= launch_speed
      launched_actor.dy -= launch_speed
    end
    if (jon.bandolier > 5) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dx -= launch_speed
      launched_actor.dy += launch_speed
    end
    if (jon.bandolier > 6) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dx += launch_speed
      launched_actor.dy -= launch_speed
    end
    if (jon.bandolier > 7) then
      local launched_actor = make_lady(jon.x, jon.y)
      add(actor, launched_actor)
      jon.bandolier -= 1
      launched_actor.dx += launch_speed
      launched_actor.dy += launch_speed
    end
end

function handle_lady_collision(player_actor, lady_actor)
  if(lady_actor.spr == lady_sprite and player_actor.spr == jon_sprite) then
    -- reduce jon's cash
    jon.cash -= 1
    delete_actor(lady_actor)
    -- pickup ladies
    jon.bandolier += 1
  end
end

-- true if a will hit another
-- actor after moving dx,dy
function solid_actor(a, dx, dy)
  for a2 in all(actor) do
    if a2 != a then
    local x=(a.x+dx) - a2.x
    local y=(a.y+dy) - a2.y
    if ((abs(x) < (a.w+a2.w)) and
        (abs(y) < (a.h+a2.h)))
    then

      -- moving together?
      -- this allows actors to
      -- overlap initially 
      -- without sticking together    
      if (dx != 0 and abs(x) <
          abs(a.x-a2.x)) then
        v=a.dx + a2.dy
        a.dx = v/2
        a2.dx = v/2

        sfx(61)

        handle_tsnow_collision(a, a2)
        handle_spidy_collision(a, a2)
        handle_lady_collision(a, a2)
        handle_ai_bit_collision(a, a2)
        handle_trs80_collision(a, a2)

        return true 
      end

      if (dy != 0 and abs(y) <
          abs(a.y-a2.y)) then
        v=a.dy + a2.dy
        a.dy=v/2
        a2.dy=v/2

        sfx(61)

        handle_tsnow_collision(a, a2)
        handle_spidy_collision(a, a2)
        handle_lady_collision(a, a2)
        handle_ai_bit_collision(a, a2)
        handle_trs80_collision(a, a2)

        return true 
      end
      
      --return true
      
    end
    end
  end
  return false
end

-- checks both walls and actors
function solid_a(a, dx, dy)
  if solid_area(a.x+dx,a.y+dy,
    a.w,a.h) then
    return true end
  return solid_actor(a, dx, dy) 
end

function draw_actor(a)
  local sx = (a.x * 8) - 4
  local sy = (a.y * 8) - 4

  if (a.spritesize==1) then
    palt(0, false)
    palt(13,true)
    spr(a.spr + a.frame, sx, sy)
  end

  if (a.spritesize==2) then
    frameoffset = flr(a.frame) == 0 and 0 or 16
    sspr(32+frameoffset,16,16,8,sx,sy)
  end

  if (a.spritesize == 4) then
  -- TODO: fix this to be dynamic right now it just loads the trs80
    palt(0, false)
    palt(13,true)
    sspr(64, 8, 16, 16, sx, sy)
  end

  palt()
end

-->8
-- player

function reset_player()
  jon.x = startx+1
  jon.y = starty+1
end

function init_player()
  if (player_initialized == 1) return
  player_initialized = 1

  -- jon
  jon = {}

  jon.x = startx+1
  jon.y = starty+1
  jon.spritesize = 1
  jon.dx=1
  jon.dy=-0.1
  jon.inertia=0.5
  jon.frame = 0
  jon.t = 0
  jon.bounce  = 1

  -- half-width and half-height
  -- slightly less than 0.5 so
  -- that will fit through 1-wide
  -- holes.
  jon.w = 0.4
  jon.h = 0.4

  jon.bandolier = 0
  jon.spr = 0
  jon.thunder_power = 1
  jon.cash = 0
  jon.frames = 3
  jon.player = true
  jon.aibits = 0
  jon.actor_id = 0
end

function payday()
  jon.cash += 10
end

function sober_up()
  if jon.thunder_power > 2 then
    jon.thunder_power -= 1
  end
end

function jonny_cash_mode()
    pal(15, 7)
    -- pal(0, 5)
    pal(1, 0)
    pal(12, 0)
    jon_accel = jon_accel_upper_limit
end

function update_player()
  if time() % 2 == 0 then
    payday()
    sober_up()
  end

  if (jonny_cash_enabled == 1) then
    jonny_cash_mode()
  elseif jon.thunder_power > 65 then
    jonny_cash_mode()
  elseif jon.thunder_power > 45 then
    jon_accel = jon_initial_speed + (jon_initial_speed/2)
  elseif jon.thunder_power > 25 then
    jon_accel = jon_initial_speed + (jon_initial_speed/3)
  else
    jon_accel = jon_initial_speed
  end

  -- message("jon accel: "..jon_accel)
end

function control_player(pl)
  local prev_x = pl.x
  local prev_y = pl.y

  if (mget(jon.x, jon.y) == portal_sprite) advance_game_state()

  -- leftup
  if (btn(0) and btn(2)) then
    pl.dx -= jon_accel
    pl.dy -= jon_accel
    last_btn = left_up
  -- leftdown
  elseif (btn(0) and btn(3)) then
    pl.dx -= jon_accel
    pl.dy += jon_accel
    last_btn = left_down
  -- rightup
  elseif (btn(1) and btn(2)) then
    pl.dx += jon_accel
    pl.dy -= jon_accel
    last_btn = right_up
  -- rightdown
  elseif (btn(1) and btn(3)) then
    pl.dx += jon_accel
    pl.dy += jon_accel
    last_btn = right_down
  elseif (btn(0)) then
    pl.dx -= jon_accel
    last_btn = left
  elseif (btn(1)) then
    pl.dx += jon_accel
    last_btn = right
  elseif (btn(2)) then
    pl.dy -= jon_accel
    last_btn = up
  elseif (btn(3)) then
    pl.dy += jon_accel
    last_btn = down
  end

  if(btnp(4)) launch_actor()
  if(btnp(5)) multi_dir_attack()

  -- update camera
  cam_x = pl.x
  cam_y = pl.y

  -- play a sound if moving
  -- (every 4 ticks)

  if (abs(pl.dx)+abs(pl.dy) > 0.1
      and (pl.t%4) == 0) then
    if (sfx_enabled == 1) sfx(9)

  end
end
-->8
-- generate map

function is_within_map(x, y)
  if (y == 0) return false

  if (x == 0) return false

  if (x >= mapsize) return false

  if (y >= mapsize) return false

  return true
end

-->9
-- window system

-- we have a stack of windows, when the player hits the ❎ btn (i.e. btn(5))
--   the window should perform some action (i.e. a callback should fire). 
--   Typically the window closes

windows = {}

function draw_windows()
  if #windows > 0 then
    local lines = get_lines_from_message(windows[1].message)

    local line_height = 10
    local startx = 10
    local starty = 30
    local endx = 115
    local endy = #lines + (line_height * 7) + 12
    local color = 11



    rectfill(startx, starty, endx, endy, 0)

    clip(startx, starty, endx-12, endy)

    local line_num = windows[1].line

    -- print lines that we already typed
    for i = 1, #lines do
      if line_num > i then
        print(lines[i], startx + 2, starty - 4 + line_height * i, color)
      end
    end

    -- type out a line
    print(animate_typing(lines, line_num), startx + 2, starty - 4 + line_height * line_num, color)

    print("❎", endx-10, endy-7, color)
    clip()
    rect(startx, starty, endx, endy)
  end
end

function get_lines_from_message(msg)
  local lines = {}
  local line_num = 1
  local words = split(msg, " ")

  for w in all(words) do
    -- if the line is empty, add the first word
    if (type(lines[line_num]) == "nil") then
      lines[line_num] = w
    else
      -- if adding the line fills up the line, 
      -- wrap to the next line
      -- plus one for a space at the end
      if (#lines[line_num] + #w + 1 > line_char_count) then
        line_num+=1
      end

      -- if the line is empty, 
      -- add the first word
      if (type(lines[line_num]) == "nil") then
        lines[line_num] = w

      -- otherwise concat to teh end of the line
      else
        lines[line_num] = lines[line_num].." "..w
      end
    end
  end

  return lines
end

-- split string
function split(str,d,dd)
  local a={}
  local c=0
  local s=''
  local tk=''

  if dd~=nil then str=split(str,dd) end
  while #str>0 do
  if type(str)=='table' then
    s=str[1]
    add(a,split(s,d))
    del(str,s)
  else
    s=sub(str,1,1)
    str=sub(str,2)
    if s==d then 
    add(a,tk)
    tk=''
    else
    tk=tk..s
    end
  end
  end
  add(a,tk)
  return a
end

function animate_typing(lines, line_num)
  if windows[1].line > line_num  then 
    return lines[line_num]
  end

  if (windows[1].char < #lines[line_num]) sfx(63)
  windows[1].char += 1

  if windows[1].char % line_char_count == 0 then
    if windows[1].line + 1 <= #lines then
      windows[1].line += 1
      windows[1].char = 0
    end
  end

  return sub(lines[line_num], 1, windows[1].char)
end


-- window callback should be what fires when a window is closed
function default_window_callback()
end

function make_window()
  local window = {}
  -- char is which character index we have last typed
  --   used for animation
  window.char = 0
  -- line is used to type one line at a time
  --   used for animation
  window.line = 1
  window.message = "This is a rather long message.  However, I just wanted to test that we are wrapping correctly"
  window.callback = default_window_callback

  add(windows, window)

  return window
end

function handle_window(w)
  if btnp(5) then
    del(windows, w)
    w.callback()
  end
end

-- stats

spidys_killed = 0
spidys_killed_boss_fight = 0
total_tsnow_collected = 0

function count_spidy(level)
  if (game_state > setup_boss_fight) then
    spidys_killed_boss_fight += 1
  else
    spidys_killed += 1
  end
end

function count_tsnow()
  total_tsnow_collected += 1
end

__gfx__
111111ddd11111ddd11111dd111111dd000a0a00000808000000000066066665dddddddddddddddd511111150000000000000000000000000000000000000000
11111111111111111111111111111111aaaaaaaa888888880000000065066555d0dddddddddddddd51eeee150000000000000000000000000000000000000000
f6ff6fdddf6ff6fddfff6ffdf6ff6fdda00a0a00800808000000000000600000dddddddddddddddd51eaae150000000000000000000000000000000000000000
ffffffdddffffffddffffffdffffffddaaaaaaaa888888880000000066666066dddddddddddddddd51eaae150000000000000000000000000000000000000000
dcccddddddcccdddddcccddddcccdddd000a0a0a000808080000000065655055dddddddddddddddd51eaae150000000000000000000000000000000000000000
d111dddddd111ddddd1111ddd111dddd000a0a0a000808080000000000000000dddddddddddddddd51eaae150000000000000000000000000000000000000000
d1d1dddd011d110d011dd1dd11d1ddddaaaaaaaa888888880000000066666666dddddd7ddddddddd51eeee150000000000000000000000000000000000000000
00d00ddd0ddddd0d0dddd00dddd00ddd000a0a00000808000000000055665500ddddddd7dddddddd511111150000000000000000000000000000000000000000
dddddddddddddddddddddddd00000000dddddddddddddddddddddddd00000000ddd555555555555500000000000000008888888888888888bbbbbbbbbbbbbbbb
d88d88ddd88d88ddd88d88dd000000006d6d6d6d6d6d6d6d6d6d6d6d00000000dd5566666666666500000000000000008888888888888888bbbbbbbbbbbbbbbb
8888878d8888878d8888878d00000000bbbbbbbbbbbbbbbbbbbbbbbb00000000dd5600000006555500000000000000008888888888888888bbbbbbbbbbbbbbbb
8888888d8888888d8888888d00000000b101b01bb101b01bb101b01b00000000dd560b0bb075000500000000000000008888888888888888bbbbbbbbbbbbbbbb
d88888ddd88888ddd88888dd00000000b101b01bb101b01bb101b01b00000000dd56000000c5000500000000000000008888888888888888bbbbbbbbbbbbbbbb
dd888ddddd888ddddd888ddd00000000bbbbbbbbbbbbbbbbbbbbbbbb00000000dd56000bb005555500000000000000008888888888888888bbbbbbbbbbbbbbbb
ddd8ddddddd8ddddddd8dddd000000006d6d6d6d6d6d6d6d6d6d6d6d00000000dd560c000005000500000000000000008888888888888888bbbbbbbbbbbbbbbb
dddddddddddddddddddddddd00000000dddddddddddddddddddddddd00000000dd5650000005000500000000000000008888888888888888bbbbbbbbbbbbbbbb
dddddddddddddddddddddddd0000000000040000000040000000000000000000dd5665066065555500000000000000008888888888888888bbbbbbbbbbbbbbbb
dddddddddddddddddddddddd0000000000404000000404000044400000044400d56655555555666500000000000000008888888888888888bbbbbbbbbbbbbbbb
dddddddddddddddddddddddd0000000004000401104000400400040110400040556666666666666500000000000000008888888888888888bbbbbbbbbbbbbbbb
ddd77dddddd77dddddd77ddd0000000040040041140040044004004114004004560505050505050500000000000000008888888888888888bbbbbbbbbbbbbbbb
ddd7677dddd7677dddd7677d0000000000404045540404000040409559040400505050505050566500000000000000008888888888888888bbbbbbbbbbbbbbbb
dd77777ddd777c7ddd77777d0000000004000458854000400400099889900040550505050505665500000000000000008888888888888888bbbbbbbbbbbbbbbb
d7667677d7777677d76676770000000040000084480000040040008998000400566666666666655d00000000000000008888888888888888bbbbbbbbbbbbbbbb
777777777676777777777777000000000000000880000000000000088000000055555555555555dd00000000000000008888888888888888bbbbbbbbbbbbbbbb
d3bb33ddd33bbbddd333bbdd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbfbbbdb3bbfbbd33bbfbbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31ff1fbd3f1ff1bd3f1f1fbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bffffbd3bffffbd3bffffbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2f2bdd3b2f2bdd3b2f2bdd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dff2ffddddff2ffdff2ffddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
def2feddddfe2fedef2efddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd8d8ddddd2d2ddddd2d2ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeee000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeefee00000000000000000000000000000
00000000000011111100000000000000000000000000000000000000000000000000000000000000000000000000ef1ff1e00000000000000000000000000000
00000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000eeffffe00000000000000000000000000000
000000000000f6ff6f00000000000000000000000000000000000000000000000000000000000000000000000000ee2f2e000000000000000000000000000000
000000000000ffffff000000000000000000000000000000000000000000000000000000000000000000000000000ff2ff000000000000000000000000000000
0000000000000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000ef2fe000000000000000000000000000000
00000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000000
00000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000055055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000088088000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000888887800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000888888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000088888000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000008880000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000767700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000076676770000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777770000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700000777000000000000000000000000000000000000000000000000000007070000077700000000000000000000000000000000000000000000000000000
70700000007000000000000000000000000000000000000000000000000000007070000000700000000000000000000000000000000000000000000000000000
07000000777000000000000000000000000000000000000000000000000000007770000077700000000000000000000000000000000000000000000000000000
70700000700000000000000000000000000000000000000000000000000000000070000070000000000000000000000000000000000000000000000000000000
70700000777000000000000000000000000000000000000000000000000000007770000077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000002000000000000000000000000000000000000000000000000040404000000000000000000000000000606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001013000600002000000009130000000c130000000000000000000000000000000000000000000000111300000000000000000e1300000010130000000000000000000000000000000000000000000000
011000000c03328d0029d002bd000c5330000000000000000c0330000000000000000c5330000000000000000c0330000000000000000c5330000000000000000c0330000000000000000c533000000000000000
0110000000000000011d0101f01020011210112301124012280112801128011280112801128011280112801126011260112601126011260112601126011260152401124011240112401124011240112401124013
0110000024b3300b0318b3300b0300b0324b3300b0300b0324b3300b0300b0300b0300b0300b0300b0300b0324b3300b0318b3300b0300b0324b3300b0300b0324b3300b0300b0300b0300b0300b0300b0300b03
01100000093200000000000000000c320000000000000000103201032110321103210000000000093200000000000000000c3200000000000000000e320000001032000000000000000000000000000000000000
01100000093200000000000000000c320000000000000000103201032110321103210000000000093200000000000000001c32000000000001a32000000000001832000000000000000000000000000000000000
01100000004050040518415184120040500405184151840518405184051c4151c41218405184051c4151840518405184051a4151a41218405184051a415184051840518405184151841218405184051841500405
01100000021320213202132021320c1320e1320e1320e132021320213202132021320213200132001320c1320e1320e1320e1320e1320e1320e1320513205132051320513205132051320c1320c1320c1320c132
0110000000000000011d0101f010200112101123011240122801128011280112801128011280112801128011260002600026000260002600026000260002600005000290001d0101f01020011210112301124012
0110000018314183111831118311183111831118311183111f3141f31113311133111331113311133111331121314180001d3122b312000002131218312180002131418000133120c31200000213121831200000
011000000cc430cd430cc430c0430e6430cc430c0430cc430cc43000000cc430c0430e6430cc430c0430cc430cc430cd430cc43000000e6430cc430c0430cc430cc43000000cd43000000e643000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f030000000000000000180300000000000000001c030000000000000000130300000000000000001f030000000000000000180300000000000000001f03000000000000000021030000000000000000
011000001d1440000400004000040000400004000040000400004000040000400004000040000400004000041c144000040000400004000040000400004000040000400004000040000400004000040000400004
011000001a1440000400004000040000400004000040000400004000040000400004000040000400004000041f144000040000400004000040000400004000040000400004000040000400004000040000400004
011000001f5211f52113521135211c5211c5211c5211c52117520175211752117521005010050100501005011f5201f5211f5211f5211a5211a5211a5211a5211552115521155211552100501005010050100000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000050200802000000000000000000000110201402000000000000000000000000001f0202002000000000002b0002d0202e0202f0202b0001a0002100017000140001500016000180001a0001d00000000
001a00000941000000000000740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000003530051300a1300d530125301653011130095300f53015530195301e5301a500000001a50015500000001c5001a50015500115000000000000000000000000000000000000000000000000000000000
000700002a0002d0102f0103101034010310003100032000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000103003630126000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001c620176200402029020270201f0200b02018020110200d02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000d7300d700040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01024346
00 01024646
00 01020346
00 01020346
00 01020307
00 01020307
00 01024344
00 01024344
00 01020344
00 01020344
00 05024344
02 06024344
01 080b494a
00 080b4344
00 080b4344
01 080b094a
01 080b094a
02 080b090a
00 41424344
00 41424344
01 14554344
00 14154344
00 14164344
00 14151744
00 14161744
00 14151744
02 14161744

