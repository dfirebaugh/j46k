pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- j46k
-- by dfire

debug = 0

-- additional_perimeter_checks is used in map generation
--   it represents how many neighbor tiles to checkout 
--   starting with the adjacent neighbors then tiles that
--   are adjacent to those neighbors
additional_perimeter_checks = 4

dig_iteration_limit = 2000

mapsize = 64
startx = 1
starty = 1
wall=7
floor=9
sfx_enabled=0

-- spawn chances
lady_spawn_number = 2
spidy_spawn_number = 2
tsnow_spawn_number = 8
aibit_spawn_number = 5

-- sprites
tsnow_sprite = 32
lady_sprite = 48
spidy_sprite = 36
aibit_sprite = 20

-- actor ids:
player_id = 0
lady_id = 1
tsnow_id = 2
aibit_id = 3
spidy_id = 4

lady_attack_modifier = 20
launch_speed = 1.8
lady_inertia = .8
lady_inertia_cap = 1
lady_inertia_inc = 0--.08
lady_bounce = 1
lady_speed = 1
lady_return_rate = .2

spidy_follow_rate = .01
spidy_aggro_distance = 5

jon_sprite = 0
jon_attack_modifier = 1
thunder_power_attack_modifier = 1

-- tsnow_increment is how much
--  it will increase jon's thunderpower
tsnow_increment = 10
spidy_health = 100

-- game_states:
setup_intro_level = 0
play_intro_level = 1
setup_generated_level = 2
play_generated_level = 3

-- game state:
game_state = setup_intro_level

-- music(0)
cam_x = 0
cam_y = 0

last = 0
msg_color = 1



function check_for_message()
  if flr(time()) - last == 2 then
    gmsg = nil
  end

  if (gmsg != nil) then
    rectfill(0, 0, 128, 6, 0)
    print(gmsg, 5, 0, msg_color)
  end
end

function message(msg)
    last = flr(time())
    msg_color = (msg_color + 1) % 15 + 1
    gmsg = msg
end

function _update()
  if(game_state == setup_intro_level) then
    init_intro_level()
    game_state += 1
  elseif (game_state == play_intro_level) then
    update_intro_level()
  elseif (game_state == setup_generated_level) then
    init_generated_level()
    game_state += 1
  elseif(game_state == play_generated_level) then
    update_generated_level()
  end
end

function _draw()
  cls()
  if(game_state == play_intro_level) then
    draw_intro_level()
    check_for_message()
  elseif (game_state == setup_generated_level) then
  elseif (game_state == play_generated_level) then
    draw_generation_level()
  end
end

function init_intro_level()
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
  init_player()
  place_lady(5, 5)
  place_lady(5, 10)
  place_lady(2, 5)
  place_tsnow(5, 8)
  place_tsnow(5, 10)
  place_tsnow(5, 11)
  place_spidy(10, 12)
end

function update_intro_level()
  control_player(jon)
  foreach(actor, move_actor)
  
  if(jon.x > 13 and jon.y < 3) then
    
    -- foreach(actor, delete_actor)
    game_state += 1
    delete_all_actors()
  end
end

function draw_intro_level()
  camera(0, 0)

  map(0, 0, 0, 0, 16, 16)

  -- draw actors
  foreach(actor,draw_actor)
  print("->skip", 95, 12, 7)
  draw_game_info()
end

function init_generated_level()
  -- fill the map with walls
  fillmap()
  dig(startx, starty)

  -- set start position
  mset(startx,starty,floor)
  mset(startx+1, starty, floor)
  mset(startx, starty+1, floor)
  mset(startx+1, starty+1, floor)

  init_actors()
  init_player()

  
  place_lady(5, 5)
  place_lady(5, 10)
  place_lady(2, 5)
  place_lady(2, 25)
end

function update_generated_level()
  control_player(jon)
  foreach(actor, move_actor)
  if time() % 2 == 0 then
    payday()
  end
end

function draw_generation_level()
  cls()
  camera(cam_x^1.5, cam_y^1.5)

  map(0, 0, 0, 0, 128, 128)

  -- draw actors
  foreach(actor,draw_actor)

  camera() -- resets camera postion to static so we can draw game info
  if (debug == 1) then
    print("floors: "..floorcount, 0, 112, 7)
    print("iterations: "..iterations, 0, 100, 7)
    -- log jon's coordinates
    print("x "..jon.x,0,120,7)
    print("y "..jon.y,64,120,7)
    print('('..cam_x..', '..cam_y..')', 0, 0, 7)
  end
  draw_game_info()
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

-->8
-- actor
actor = {} --all actors in world

-- inserts actor to the map
-- if the cell is already occupied, we try again
function insert_actor(actor_type)
  local rndx = rnd(mapsize) + 1
  local rndy = rnd(mapsize) + 1

  if (mget(rndx, rndy) == floor) then
    place_actor(rndx, rndy, actor_type)
    return
  end

  insert_actor(actor_type)
end
-- init_actors
-- initializes starting actors
function init_actors()
  -- iterate through the map and place actors
  for i = 0, spidy_spawn_number do
    insert_actor(spidy_id)
  end

  for i = 0, aibit_spawn_number do
    insert_actor(aibit_id)
  end

  for i = 0, tsnow_spawn_number do
    insert_actor(tsnow_id)
  end
end

function place_actor(x, y, actor_type)
  if (actor_type == spidy_id) place_spidy(x,y)

  if (actor_type == aibit_id) place_aibit(x, y)

  if (actor_type == tsnow_id) place_tsnow(x, y)
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
  
  add(actor,a)add(actor,a)

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
function move_actor(a)

  -- if it's a lady 
  --   move toward jon
  if (a.actor_id == lady_id) move_lady(a)

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
  spidy.spr = 36
  spidy.name = "spidy"
  spidy.health = spidy_health
  spidy.actor_id = spidy_id
end

function place_aibit(x, y)
  aibit = make_actor(x, y)
  aibit.spr = 20
  aibit.actor_id = aibit_id
end

function place_tsnow(x, y)
  tsnow = make_actor(x, y)
  tsnow.spr = tsnow_sprite
  tsnow.actor_id = tsnow_id
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
  for i=1, count(actor) do
    if (actor[i].x == a.x and actor[i].y == a.y and actor[i].actor_id == a.actor_id) then
      del(actor, actor[i])
      return
    end
  end
end

function handle_ai_bit_collision(a, aibit_actor)
  if(aibit_actor.spr == aibit_sprite) then
    if (a.player) then
      jon.aibits += 1
      message("picked up aibit")
    end
    delete_actor(aibit_actor)
  end
end

function handle_tsnow_collision(a, a2)
    -- if actor collides with some thunder snow
    if(a2.spr == tsnow_sprite) then
      -- if actor happens to be a lady
      if (a.spr == lady_sprite) then
        if (a.inertia > lady_inertia_cap) then
        else
          a.inertia = (a.inertia + lady_inertia_inc)
        end
      end

      if (a.spr == jon_sprite) then
        -- cap thunderpower at 100
        jon.thunder_power = (jon.thunder_power+tsnow_increment > 100) and 
          100 or (jon.thunder_power + 10)

        message("picked up some thunder snow!")
      end

      delete_actor(a2)
    end
end

function handle_spidy_collision(a, spidy)
  if(spidy.spr == spidy_sprite) then
      -- if actor happens to be a lady
      if (a.spr == lady_sprite) then
        -- a.inertia -= .1
        -- reduce spidy's health
        spidy.health -= lady_attack_modifier
      end

      if (a.spr == jon_sprite) then
        spidy.health -= jon_attack_modifier + (jon.thunder_power + thunder_power_attack_modifier)
        message(jon_attack_modifier + (jon.thunder_power + thunder_power_attack_modifier).." dmg to spidy. lost: aibit")
        if (jon.aibits > 0) then
          jon.aibits -= 1
          jon.thunder_power -= 20
          if (jon.thunder_power < 0) then
            jon.thunder_power = 0
          end
        end
      end

      if (spidy.health < 0) then
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

function launch_actor()
  if(jon.bandolier > 0) then
    jon.bandolier -= 1
    local launched_actor = make_lady(jon.x, jon.y)
    add(actor, launched_actor)
    launched_actor.dx = 0
    launched_actor.dy = 0

    if (btn(0)) then
      launched_actor.dx -= launch_speed
    end
    if (btn(1)) then
      launched_actor.dx += launch_speed
    end
    if (btn(2)) then
      launched_actor.dy -= launch_speed
    end
    if (btn(3)) then
      launched_actor.dy += launch_speed
    end
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

        handle_tsnow_collision(a, a2)
        handle_spidy_collision(a, a2)
        handle_lady_collision(a, a2)
        handle_ai_bit_collision(a, a2)

        return true 
      end

      if (dy != 0 and abs(y) <
          abs(a.y-a2.y)) then
        v=a.dy + a2.dy
        a.dy=v/2
        a2.dy=v/2
        handle_tsnow_collision(a, a2)
        handle_spidy_collision(a, a2)
        handle_lady_collision(a, a2)
        handle_ai_bit_collision(a, a2)

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
  spr(a.spr + a.frame, sx, sy)
  end

  if (a.spritesize==2) then
    frameoffset = flr(a.frame) == 0 and 0 or 16
    sspr(32+frameoffset,16,16,8,sx,sy)
  end
end

-->8
-- player

function init_player()
  -- jon
  jon = make_actor(startx+1, starty+1)
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

function control_player(pl)
  local prev_x = pl.x
  local prev_y = pl.y

  -- how fast to accelerate
  accel = 0.1
  if (btn(0)) then
    pl.dx -= accel
  end
  if (btn(1)) then
    pl.dx += accel
  end
  if (btn(2)) then
    pl.dy -= accel
  end
  if (btn(3)) then
    pl.dy += accel
  end

  if(btnp(4)) launch_actor()

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
iterations=0
floorcount=0

function fillmap()
 for i=0,mapsize do
  for j=0, mapsize do
    mset(i,j,wall)
  end
 end
end

-- picks a random direction and 
--   returns a new position {x, y}
--   returns false if no good options in adjacent cells
function newdirection(x, y)
  local inc = 1

  local possibledirections = {
    {x = x+inc, y = y}, -- right
    {x = x-inc, y = y}, -- left
    {x = x, y = y-inc}, -- up
    {x = x, y = y+inc}, -- down
    -- {x = x+inc, y = y+inc}, -- diagonal top right
    -- {x = x+inc, y = y-inc}, -- diagonal bottom right
    -- {x = x-inc, y = y-inc}, -- diagonal top left
    -- {x = x-inc, y = y+inc}, -- diagonal bottom left
  }
  local rnddir= flr(rnd(count(possibledirections)))

  for j=0, additional_perimeter_checks do
    -- try all 4 possible directions
    for i=0, count(possibledirections) do
      rdir = (rnddir+i % count(possibledirections))+1
      if(is_within_map(
          possibledirections[rdir].x, 
          possibledirections[rdir].y) and 
          possibledirections[rdir] != floor) then
        return possibledirections[rdir]
      end
    end
    inc += 1
  end

  -- if we don't get a good option return false
  return false
end

-- dig takes a position and based on that it will 
--   place floors instead of walls
function dig(x, y)
  local next = newdirection(x, y)
  if (next == false) return

  local nexttile = mget(next.x, next.y)

  iterations += 1
  -- base condition: if floor 
  --  count is greater than 
  --  predetermined set value, 
  --  break the loop
  if (iterations == dig_iteration_limit) then
    return
  else -- else dig out a floor
    floorcount += 1 -- keep a count of how many floor tiles we've placed
    mset(next.x, next.y, floor) -- set a floor tile
    dig(next.x, next.y)
  end
end

function is_within_map(x, y)
  if (y == 0 or x == 0) return false

  if (x >= mapsize or y >= mapsize) return false

  return true
end

-- check_neighbors looks at the 
--   neigboring tiles around a tile
--   to see if they are floor tiles
--
--   returns true if all neighbors are floors
function check_neighbors(x, y)
  local neighbors = {
    {x = x + 1, y = y}, -- right
    {x = x - 1, y = y}, -- left
    {x = x, y = y - 1}, -- up
    {x = x, y = y + 1}, -- down
  }

  for i = 1, count(neighbors) do
    if (mget(neighbors[i].x, neighbors[i].y) == wall) return false
  end

  return true
end

__gfx__
1111110001111100011111001111110000000000000000000000000066066666dddddddddddddddd000000000000000000000000000000000000000000000000
1111111111111111111111111111111100000000000000000000000066066666d0dddddddddddddd000000000000000000000000000000000000000000000000
f6ff6f000f6ff6f00fff6ff0f6ff6f0000000000000000000000000000600000dddddddddddddddd000000000000000000000000000000000000000000000000
ffffff000ffffff00ffffff0ffffff0000000000000000000000000066666066dddddddddddddddd000000000000000000000000000000000000000000000000
0ccc000000ccc00000ccc0000ccc000000000000000000000000000065666066dddddddddddddddd000000000000000000000000000000000000000000000000
0111000000111000001111000111000000000000000000000000000000000000dddddddddddddddd000000000000000000000000000000000000000000000000
0101000051101150511001001101000000000000000000000000000066566656dddddd7ddddddddd000000000000000000000000000000000000000000000000
5505500050000050500005500005500000000000000000000000000066666666ddddddd7dddddddd000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08808800088088000880880000000000606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000
88888780888887808888878000000000bbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
88888880888888808888888000000000b101b01bb101b01bb101b01b000000000000000000000000000000000000000000000000000000000000000000000000
08888800088888000888880000000000b101b01bb101b01bb101b01b000000000000000000000000000000000000000000000000000000000000000000000000
00888000008880000088800000000000bbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
00080000000800000008000000000000606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000400000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000004040000004040000444000000444000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000040004011040004004000401104000400000000000000000000000000000000000000000000000000000000000000000
00077000000770000007700000000000400400411400400440040041140040040000000000000000000000000000000000000000000000000000000000000000
00076770000767700007677000000000004040455404040000404095590404000000000000000000000000000000000000000000000000000000000000000000
0077777000777c700077777000000000040004588540004004000998899000400000000000000000000000000000000000000000000000000000000000000000
07667677077776770766767700000000400000844800000400400089980004000000000000000000000000000000000000000000000000000000000000000000
77777777767677777777777700000000000000088000000000000008800000000000000000000000000000000000000000000000000000000000000000000000
03bb3300033bbb000333bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbfbbb0b3bbfbb033bbfbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31ff1fb03f1ff1b03f1f1fb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bffffb03bffffb03bffffb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b2f2b003b2f2b003b2f2b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ff2ff0000ff2ff0ff2ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ef2fe0000fe2fe0ef2ef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00808000002020000020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0110000000472004620c3400c34318470004311842500415003700c30500375183750c3000c3751f4730c375053720536211540114330c37524555247120c3730a470163521d07522375164120a211220252e315
01100000183732440518433394033c65539403185432b543184733940318433394033c655306053940339403184733940318423394033c655394031845321433184733940318473394033c655394033940339403
01100000247552775729755277552475527755297512775524755277552b755277552475527757297552775720755247572775524757207552475227755247522275526757297552675722752267522975526751
01100000001750c055003550c055001750c055003550c05500175180650c06518065001750c065003650c065051751106505365110650c17518075003650c0650a145160750a34516075111451d075113451d075
011000001b5771f55722537265171b5361f52622515265121b7771f76722757267471b7461f7362271522712185771b5571d53722517187361b7261d735227122454527537295252e5171d73514745227452e745
01100000275422754227542275422e5412e5452b7412b5422b5452b54224544245422754229541295422954224742277422e7422b7422b5422b5472954227542295422b742307422e5422e7472b547305462e742
0110000030555307652e5752b755295622e7722b752277622707227561297522b072295472774224042275421b4421b5451b5421b4421d542295471d442295422444624546245472444727546275462944729547
0110000000200002000020000200002000020000200002000020000200002000020000200002000020000200110171d117110171d227131211f227130371f2370f0411b1470f2471b35716051221571626722367
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e775000002e1752e075000002e1752e77500000
010400001065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00044208
00 00044108
00 00010304
00 00010304
01 00010203
00 00010203
00 00010305
00 00010306
00 00010305
00 00010306
00 00010245
02 00010243

