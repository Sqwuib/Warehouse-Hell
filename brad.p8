pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- player
px = 100
py = 240
pvx = 0
pvy = 0
spd = 1
plrspr = 1
player_frozen = false
facing = 1 -- 1=down, 2=up, 3=right, 4=left
base_spd = 1
sprint_spd = 1.8

-- cart
cx = 105
cy = 240
cvx = 0
cvy = 0
crtspr = 5

-- camera
camx = 0
camy = 0

-- interaction tuning
push_dist = 2
grab_dist = 8

-- grab state
grabbing = false
was_grabbing = false
grab_timer = 0

-- carrying state
carrying = false
carry_dir = 1
cart_level = 0

-- arrow state
arrow_frame = 0
arrow_timer = 0
debug_arrows = {}
left_tiles = {
 [66]=true,[82]=true,[85]=true,[98]=true,[114]=true,[86]=true
}

right_tiles = {
 [77]=true,[93]=true,[109]=true,[125]=true,[94]=true,[95]=true
}

-- hud
order_count = 0
energy = 100
money = 0

-- boss
shadow_frame = 0
shadow_timer = 0

shadow_x = 0
shadow_y = 0
shadow_vx = 0
shadow_vy = 0
shadow_step_timer = 0
shadow_spd = 1
shadow_last_target_x = -1
shadow_last_target_y = -1

shadow_state = "idle"
shadow_wait = 300 + rnd(300)
shadow_pause = 0

shadow_lines = {
    "so i saw on reddit...",
    "quick one before you go",
    "did you watch the game last night?",
    "back in my day we didn't have this",
    "just a quick chat",
    "you busy?",
    "i'll be quick i promise",
    "have you got a minute?",
    "any plans for the weekend?",
    "you know what the problem is...",
    "we should circle back on this",
    "just looping you in",
    "while i've got you...",
    "this won't take long",
    "you got a sec?",
    "blah blah blah",
    "hear about trump?",
    "i'm here to annoy you"
}

current_line = ""
text_progress = 0

-- time system
day = 1
time_of_day = 0
day_length = 5400 -- longer day (tweak later)

shift_start = 7
shift_end = 16
shift_hours = shift_end - shift_start

stream_hype = false
stream_timer = 0
stream_wait = 300 + rnd(300) -- random delay before next event
viewer_count = 12483
pog_x = 128

stream_flash = 0

-- phone system / penalties
checking_phone = false
caught_on_phone = false
discipline_active = false
discipline_timer = 0
discipline_lines = {}

-- order system
order_active = false
first_order = false

-- table positions (adjust if needed)
order_table_x = 32
order_table_y = 120

pack_table_x = 96
pack_table_y = 120

-- packing
packing = false
pack_progress = 0

-- shop
shop_open = false
shop_index = 1

shop_items={
 {name="energy drink",cost=20,effect="energy"},
 {name="gloves",cost=35,effect="gloves"},
 {name="tome",cost=60,effect="tome"},
 {name="trolley magnet",cost=80,effect="magnet"},
 {name="pto",cost=100,effect="pto"}
}

--item activations
energy_boost_timer=0

carry_max=1
carry_count=0
glove_level=0

tome_days=0

magnet=false

pto_days=0
last_day_pay=0

-- van
van_active = false
van_arrived = false

van_x = 75
van_y = 280
van_target_y = 248

van_speed = 0.9

-- day end
day_end = false
day_summary_timer = 0
day_earnings = 0
orders_completed_today = 0
performance_bonus = 0

-- debug
last_spawned = 0

dbg_shadow_state = ""
dbg_shadow_sx = 0
dbg_shadow_sy = 0
dbg_player_tx = 0
dbg_player_ty = 0
dbg_shadow_vx = 0
dbg_shadow_vy = 0
dbg_astar_found = false
dbg_next_tx = -1
dbg_next_ty = -1
dbg_open_count = 0

game_state="title"
game_title_started = true

music_six_started = true

title_blink=0
title_page=0
title_pages=3

--forklift
forklift_active=false
forklift_x=0
forklift_y=0
forklift_vx=0
forklift_wait=600
forklift_just_spawned = false
forklift_hit_cart=false




-- ===== helpers =====

function solid_at(x, y)
    local tile = mget(x/8, y/8)
    return fget(tile, 0)
end

function box_collide(x, y)
    local hw = 3
    local hh = 3
    local cx = x + 3
    local cy = y + 4

    return
        solid_at(cx - hw, cy - hh) or
        solid_at(cx + hw, cy - hh) or
        solid_at(cx - hw, cy + hh) or
        solid_at(cx + hw, cy + hh)
end

function cart_collide(x, y)
    local hw = 2
    local hh = 2
    local cx = x + 4
    local cy = y + 4

    return
        solid_at(cx - hw, cy - hh) or
        solid_at(cx + hw, cy - hh) or
        solid_at(cx - hw, cy + hh) or
        solid_at(cx + hw, cy + hh)
end

function arrow_exists(x, y)
    for a in all(debug_arrows) do
        if a.x == x and a.y == y then
            return true
        end
    end
    return false
end

function arrow_dir_from_flags(tx, ty)
    if fget(mget(tx+1, ty), 5) then return "right" end
    if fget(mget(tx-1, ty), 4) then return "left" end
    return "left"
end

function arrow_sprite(a)
    if a.dir == "right" then
        return 74 + arrow_frame
    else
        return 71 + arrow_frame
    end
end

function get_arrow_at_player()
    for a in all(debug_arrows) do
        if abs(px - a.x) < 4 and abs(py - a.y) < 4 then
            return a
        end
    end
    return nil
end

-- ===== random spawn =====

function spawn_random_arrows(count)

    debug_arrows = {}

    local placed = 0
    local tries = 0

    while placed < count and tries < 300 do
        tries += 1

        local tx = flr(rnd(32))
        local ty = flr(rnd(32))
        local tile = mget(tx,ty)

        local dir = nil

        if left_tiles[tile] then
            dir = "left"
        elseif right_tiles[tile] then
            dir = "right"
        end

        if dir != nil then
            local ax = tx * 8
            local ay = ty * 8

            if not arrow_exists(ax,ay) then
                add(debug_arrows,{
                    x = ax,
                    y = ay,
                    dir = dir
                })

                placed += 1
            end
        end
    end

    last_spawned = placed

    if placed == 0 then
        order_active = false
        return
    end

    order_count = placed
    order_total = placed
    cart_level = 0
    crtspr = 5
    carrying = false
    order_active = true
    
end

-- ===== shadow spawn =====

function spawn_shadow()

    local spots = {}

    local px_t = flr((px + 4) / 8)
    local py_t = flr((py + 4) / 8)

    for tx=0,39 do
        for ty=0,39 do

            if not fget(mget(tx,ty),0) then

                -- require open neighbors too
                local open =
                    shadow_can_move(tx+1,ty) or
                    shadow_can_move(tx-1,ty) or
                    shadow_can_move(tx,ty+1) or
                    shadow_can_move(tx,ty-1)

                if open then
                    local dist = abs(tx-px_t)+abs(ty-py_t)

                    if dist >= 10 and dist <= 18 then
                        add(spots,{
                            x=tx*8,
                            y=ty*8
                        })
                    end
                end
            end
        end
    end

    if #spots <= 0 then return end

    local s = spots[flr(rnd(#spots))+1]

    shadow_x = s.x
    shadow_y = s.y
    shadow_vx = 0
    shadow_vy = 0
    shadow_step_timer = 0
    music_six_started = true
    shadow_state = "moving"
end

-- ===== update =====

function _update()

    
if game_state=="title" then
    if game_title_started then
        music(5)
        game_title_started = false
    end

    title_blink += 1

    if btnp(0) then
        title_page -= 1
        if title_page < 0 then
            title_page = title_pages
        end
    end

    if btnp(1) then
        title_page += 1
        if title_page > title_pages then
            title_page = 0
        end
    end

    if btnp(4) or btnp(5) then
        game_state = "game"
        music(4)
    end

    return
end
    
    forklift_wait-=1

    if forklift_wait<=0 and not forklift_active then
    spawn_forklift_right()
    forklift_wait=0+rnd(0)
    end

    if forklift_active then
    if forklift_just_spawned then
    forklift_just_spawned=false
    else
    forklift_x+=forklift_vx
    end

    local tx=flr((forklift_x+8)/8)
    local ty=flr((forklift_y+8)/8)

    if not fget(mget(tx,ty),7) then
    forklift_active=false
    forklift_hit_cart = false
    end
    end



    if day_end then
        day_summary_timer += 1

        if day_summary_timer > 60 and btnp(4) then
            next_day()
        end

        return
    end

    if discipline_active then
        discipline_timer += 1

        -- apply punishment once
        if discipline_timer == 60 then
            money = max(0, money - 50)
        end

        -- end sequence
        if discipline_timer > 180 then
            discipline_active = false
            player_frozen = false
            caught_on_phone = false
        end

        return
    end
    if stream_hype then
        pog_x -= 2

        -- reset when it goes off screen
        if pog_x < -60 then
            pog_x = 128
        end
    end

    local h, m = get_clock_time()

    -- trigger at exactly 12:00
    if h == 12 and m == 0 and not van_active then
        van_active = true
        van_arrived = false
    end
    if h == 13 and van_active then
        van_y += van_speed

        if van_y < -16 then
            van_active = false
            van_arrived = false
        end
    end

    -- movement
    if van_active and not van_arrived then
        van_y += van_speed
        
        if van_y >= van_target_y then
            van_y = van_target_y
            van_arrived = true
        end
    end

    local at_trolley = abs(px - cx) < 10 and abs(py - cy) < 10
    
    if checking_phone and not at_trolley then
    checking_phone = false
    end

    local phone_combo_down = btn(4) and btn(5)

    if at_trolley and phone_combo_down and not phone_combo_was_down then
        checking_phone = not checking_phone
    end
    -- time always passes (even during boss)
	time_of_day += 1

    if not first_order  then
        order_count = flr(rnd(10)) + 1
        spawn_random_arrows(get_order_size())
        first_order = true
    end
    
    if time_of_day >= day_length then

        performance_bonus = 0

        if orders_completed_today >= 8 then
            performance_bonus = 120
        elseif orders_completed_today >= 5 then
            performance_bonus = 60
        elseif orders_completed_today >= 3 then
            performance_bonus = 25
        end

        money += performance_bonus
        day_earnings += performance_bonus

        day_end = true
        player_frozen = true
        day_summary_timer = 0
        return
    end
    
    if van_arrived and player_near_van() and btnp(4) and not grabbing then
        shop_open = true
        player_frozen = true
    end


    if shop_open and btnp(5) then -- x button
        shop_open = false
        player_frozen = false
    end

    if shop_open then
    if btnp(2) then shop_index -= 1 end
    if btnp(3) then shop_index += 1 end

    if shop_index < 1 then shop_index = #shop_items end
    if shop_index > #shop_items then shop_index = 1 end

    -- buy
    if btnp(4) then
        local item = shop_items[shop_index]

        if money >= item.cost then
            money -= item.cost
            apply_upgrade(item)
        end
    end

    return -- stop rest of game updating
    end

    phone_combo_was_down = phone_combo_down

    -- player input + sprint
    if not player_frozen and not checking_phone then
        local current_spd = base_spd

        if btn(5) and energy > 0 then
            current_spd = sprint_spd
            energy -= 0.1
            if energy < 0 then energy = 0 end
        end

        if btn(0) then
            pvx = -current_spd
            plrspr = 4
            facing = 4
        end
        
        if btn(1) then
            pvx = current_spd
            plrspr = 3
            facing = 3
        end
        
        if btn(2) then
            pvy = -current_spd
            plrspr = 2
            facing = 2
        end
        
        if btn(3) then
            pvy = current_spd
            plrspr = 1
            facing = 1
        end
    end

    -- very slow energy drain over time
    if energy_boost_timer>0 then
    energy_boost_timer-=-1
    energy = 100
    else
    energy-=0.001
    if energy<0 then energy=0 end
    end
	if energy < 0 then
		energy = 0
 	end
    if checking_phone and stream_hype then
        energy += 0.80
    elseif checking_phone then
        energy += 0.50
    end

    pvx = 0
    pvy = 0
    if energy > 100 then energy = 100 end

    if player_frozen then
        text_progress += 0.4

        if rnd(1) < 0.02 then
            text_progress = 0
        end
    end

    -- player input + sprint
    if not player_frozen then

        local current_spd = base_spd

        -- slower while pushing trolley
        if grabbing then
            current_spd = 0.85
        end

        -- sprint (btn 5)
        if btn(5) and energy > 0 then
            current_spd = sprint_spd
            energy -= 0.2
            if energy < 0 then energy = 0 end
        end

        if btn(0) then
            pvx = -current_spd
            plrspr = 4
            facing = 4
        end
        
        if btn(1) then
            pvx = current_spd
            plrspr = 3
            facing = 3
        end
        
        if btn(2) then
            pvy = -current_spd
            plrspr = 2
            facing = 2
        end
        
        if btn(3) then
            pvy = current_spd
            plrspr = 1
            facing = 1
        end
    end
    
    -- random small fluctuation
    if rnd(1) < 0.1 then
        viewer_count += flr(rnd(21)) - 10  -- -10 to +10
    end

    -- clamp so it doesn't go negative or insane
    if viewer_count < 1000 then viewer_count = 1000 end
    if viewer_count > 20000 then viewer_count = 20000 end
    -- carrying sprite override
				if carrying then
				    carry_dir = facing
				
				    if carry_dir == 1 then plrspr = 17 end -- down
				    if carry_dir == 2 then plrspr = 2 end  -- up
				    if carry_dir == 3 then plrspr = 19 end -- right
				    if carry_dir == 4 then plrspr = 20 end -- left
				end

    -- move player
    px += pvx
    if box_collide(px, py) then px -= pvx end

    py += pvy
    if box_collide(px, py) then py -= pvy end

    if player_frozen and not was_frozen and grabbing then
        grabbing = false

        local angle = rnd(1)
        local speed = 8 + rnd(2)

        cvx = cos(angle) * speed
        cvy = sin(angle) * speed
    end

    -- pickup with z
    -- takes priority over grabbing if standing on an arrow
    if carry_count<carry_max and not player_frozen then

        local a=get_arrow_at_player()

        if a!=nil then
            carry_count+=1
            carrying=true
            carry_dir=facing
            del(debug_arrows,a)
        end

    end
    
    -- deliver to cart
    if carry_count>0 and abs(px-cx)<6 and abs(py-cy)<6 then

    order_count-=carry_count
    if order_count<0 then order_count=0 end

    carry_count=0
    carrying=false

    local collected=order_total-order_count

    if collected>=order_total then
    cart_level=4
    crtspr=9
    else
    local progress=collected/order_total
    cart_level=flr(progress*4)
    crtspr=5+cart_level
    end

    end

    -- grab logic
    local near = abs(px - cx) < grab_dist and abs(py - cy) < grab_dist

    was_grabbing = grabbing

    -- don't start grab if you just picked up an item
    if not carrying and not player_frozen then 
        grabbing = btn(4) and near
    else
        grabbing = false
    end

    if was_grabbing and not grabbing then
        grab_timer = 15

        if pvx != 0 or pvy != 0 then
            
            cvx = pvx * 4 
            cvy = pvy * 4 
        else
            cvx = 0
            cvy = 0
        end
    end

    if grab_timer > 0 then
        grab_timer -= 1
    end

    if not grabbing and grab_timer == 0 and not player_frozen then
        if abs(px - cx) < push_dist and abs(py - cy) < push_dist then
            local weight = order_total / 4
            cvx = pvx * 1.5 - weight
            cvy = pvy * 1.5 - weight
        end
    end

    -- cart movement
    -- only drain energy if pushing while moving
    if grabbing and (pvx != 0 or pvy != 0) then
        energy -= 0.15
    end

    -- grab logic
    local near = abs(px - cx) < grab_dist and abs(py - cy) < grab_dist

    was_grabbing = grabbing

    -- don't start grab if you just picked up an item
    if not carrying and not player_frozen then
        grabbing = btn(4) and near
    else
        grabbing = false
    end

    if was_grabbing and not grabbing then
        grab_timer = 15

        if pvx != 0 or pvy != 0 then
            local weight = order_total / 4
            cvx = pvx * 4 - weight
            cvy = pvy * 4 - weight
        else
            cvx = 0
            cvy = 0
        end
    end

    if grab_timer > 0 then
        grab_timer -= 1
    end

    if not grabbing and grab_timer == 0 and not player_frozen then
        if abs(px - cx) < push_dist and abs(py - cy) < push_dist then
            cvx = pvx * 1.5
            cvy = pvy * 1.5
        end
    end

    -- cart movement
    -- only drain energy if pushing while moving
    if grabbing and (pvx != 0 or pvy != 0) then
        energy -= 0.05
    end

    if grabbing then
        -- trolley keeps a small gap and smoothly follows
        local gap = 2
        local follow = 0.5

        local target_x = px
        local target_y = py

        if pvx > 0 then target_x += gap end
        if pvx < 0 then target_x -= gap end
        if pvy > 0 then target_y += gap end
        if pvy < 0 then target_y -= gap end

        local move_x = (target_x - cx) * follow
        local move_y = (target_y - cy) * follow

        cx += move_x
        if cart_collide(cx, cy) then
            cx -= move_x
        end

        cy += move_y
        if cart_collide(cx, cy) then
            cy -= move_y
        end

        -- keep trolley's free-roll momentum from fighting the grabbed motion
        cvx = 0
        cvy = 0

    else
        cx += cvx
        if cart_collide(cx, cy) then
            cx -= cvx
            cvx = -cvx * 0.8
        end

        cy += cvy
        if cart_collide(cx, cy) then
            cy -= cvy
            cvy = -cvy * 0.8
        end

        cvx *= 0.95
        cvy *= 0.95

        if abs(cvx) < 0.05 then cvx = 0 end
        if abs(cvy) < 0.05 then cvy = 0 end
    end
    -- trolley magnet pickup
    if magnet then
        for a in all(debug_arrows) do
            if abs(cx - a.x) < 6 and abs(cy - a.y) < 6 then

                del(debug_arrows, a)

                order_count -= 1
                if order_count < 0 then
                    order_count = 0
                end

                local collected = order_total - order_count

                if collected >= order_total then
                    cart_level = 4
                    crtspr = 9
                else
                    local progress = collected / order_total
                    cart_level = flr(progress * 4)
                    crtspr = 5 + cart_level
                end

            end
        end
    end

    was_frozen = player_frozen

    -- arrow animation
    arrow_timer += 1
    if arrow_timer > 10 then
        arrow_timer = 0
        arrow_frame = (arrow_frame + 1) % 3
    end

    -- shadow animation
    shadow_timer += 1
    if shadow_timer > 8 then
        shadow_timer = 0
        shadow_frame = (shadow_frame + 1) % 4
    end

    -- countdown to next hype event
    if not stream_hype then
        stream_wait -= 1
        if stream_wait <= 0 then
            stream_hype = true
            stream_timer = 180 -- how long hype lasts
        end
    else
        stream_timer -= 1

        -- flashing animation timer
        stream_flash += 1

        if stream_timer <= 0 then
            stream_hype = false
            stream_wait = 300 + rnd(300)
        end
    end

    -- ===== shadow behaviour =====

    if shadow_state == "idle" then
        shadow_wait -= 1
        if shadow_wait <= 0 then spawn_shadow() end
    
    elseif shadow_state == "moving" then
    if music_six_started then
        music(6)
        music_six_started = false
    end
    

    dbg_shadow_state = shadow_state

    local sx = flr((shadow_x + 4) / 8)
    local sy = flr((shadow_y + 4) / 8)
    local px_t = flr((px + 4) / 8)
    local py_t = flr((py + 4) / 8)

    dbg_shadow_sx = sx
    dbg_shadow_sy = sy
    dbg_player_tx = px_t
    dbg_player_ty = py_t
    shadow_step_timer += 1

    local target_changed =
        px_t != shadow_last_target_x or
        py_t != shadow_last_target_y

        local on_tile =
        shadow_x % 8 == 0 and
        shadow_y % 8 == 0

        if on_tile and (target_changed or shadow_step_timer >= 10) then
        shadow_step_timer = 0
        shadow_last_target_x = px_t
        shadow_last_target_y = py_t

        local dist = abs(px_t - sx) + abs(py_t - sy)

        local next_tx,next_ty,found,explored

        if dist <= 6 then
            -- cheap local chase mode
            next_tx = sx
            next_ty = sy

            if px_t > sx then next_tx += 1 end
            if px_t < sx then next_tx -= 1 end
            if py_t > sy then next_ty += 1 end
            if py_t < sy then next_ty -= 1 end

            if shadow_can_move(next_tx,next_ty) then
                found = true
                explored = 1
            else
                next_tx,next_ty,found,explored =
                    shadow_find_path_step(sx,sy,px_t,py_t)
            end
        else
            next_tx,next_ty,found,explored =
                shadow_find_path_step(sx,sy,px_t,py_t)
        end
        dbg_astar_found = found
        dbg_open_count = explored or 0
        dbg_next_tx = next_tx or -1
        dbg_next_ty = next_ty or -1

        if found and next_tx != nil and next_ty != nil then
            shadow_vx = next_tx - sx
            shadow_vy = next_ty - sy
        else
            shadow_vx = 0
            shadow_vy = 0
        end

        dbg_shadow_vx = shadow_vx
        dbg_shadow_vy = shadow_vy
    end

    shadow_x += shadow_vx * shadow_spd
    shadow_y += shadow_vy * shadow_spd

    if abs(shadow_x/8 - flr(shadow_x/8)) < 0.1 then
    shadow_x = flr(shadow_x/8)*8
    end

    if abs(shadow_y/8 - flr(shadow_y/8)) < 0.1 then
    shadow_y = flr(shadow_y/8)*8
    end

    if abs(shadow_x - px) < 6 and abs(shadow_y - py) < 6 then
        shadow_x = px
        shadow_y = py
        shadow_state = "pause"
        shadow_pause = 60
        player_frozen = true
        caught_on_phone = checking_phone

        if caught_on_phone then
            discipline_active = true
            discipline_lines = {}

            local msg = {
                "we saw the phone.",
                "you chose the phone.",
                "you stared at a stranger \nplaying for you...",
                "\n",
                "what a failure",
                "you call that watching?"
            }

            for i=1,#msg do
                local from_left = rnd(1) < 0.5

                add(discipline_lines,{
                    text = msg[i],
                    x = from_left and -100 or 140,
                    target_x = 20,
                    y = 30 + (i-1)*10,
                    dir = from_left and 1 or -1,
                    delay = (i-1) * 15
                })
            end

            discipline_timer = 0
        end

        text_progress = 0
        current_line = shadow_lines[flr(rnd(#shadow_lines)) + 1]
        music(4)
    end

    elseif shadow_state == "pause" then
        shadow_pause -= 1
        if shadow_pause <= 0 then
            shadow_state = "idle"
            shadow_wait = 300 + rnd(300)
            player_frozen = false
        end
    end

    -- get new order
    local at_order = player_on_flag(6)

    if not order_active and at_order then
        order_count = flr(rnd(10)) + 1
        spawn_random_arrows(get_order_size())
    end
    
    local at_pack = player_on_flag(5)
    local ready_to_pack = order_active and order_count == 0

    if ready_to_pack and at_pack and trolley_near_tile(6,30) then
        if btn(4) then
            packing = true
            pack_progress += 0.5
        else
            packing = false
            pack_progress = 0
        end

        if pack_progress > 30 then
            complete_order()
        end
        
    end

    if forklift_active then
    forklift_x += forklift_vx
    end

    -- forklift hits trolley
    if forklift_active then
        if abs(forklift_x-cx)<10 and abs(forklift_y-cy)<10 and not forklift_hit_cart then
        cvx=forklift_vx*20
        cvy=rnd(3)-1.5
        forklift_hit_cart=true
        end
    end

        -- trolley recovery if knocked off map
    if cx < -16 or cx > 336 or cy < -16 or cy > 336 then
        cx = 105
        cy = 240
        cvx = 0
        cvy = 0
        grabbing = false
    end

    -- camera
    camx += (px - 64 - camx) * 0.2
    camy += (py - 64 - camy) * 0.2
    

end

-- ===== draw =====

function _draw()


if game_state=="title" then
    cls(1)
    rectfill(0,0,127,127,1)

    if title_page == 0 then
        print("warehouse hell",34,18,7)

        rectfill(46,58,75,73,0)
        spr(5,50,62)
        spr(1,64,62)

        if title_blink%60 < 30 then
            print("press z / x",38,94,10)
        end

        print("left/right: help",28,104,6)
        print("music from @robertduguay",17,112,5)
        print("game by sqwuib",34,120,5)

    elseif title_page == 1 then
        print("goals",54,10,7)

        rectfill(8,24,119,100,0)
        rect(8,24,119,100,7)

        print("pick the marked orders",14,32,6)
        print("carry them to the trolley",14,42,6)
        print("take trolley to packing",14,52,6)
        print("finish orders for money",14,62,6)
        print("survive each work day",14,72,8)

        print("< 1/3 >",48,106,5)
        print("left/right to change",24,116,6)

    elseif title_page == 2 then
        print("controls",46,10,7)

        rectfill(8,24,119,100,0)
        rect(8,24,119,100,7)

        print("left/right/up/down move",12,32,6)
        print("z = grab / interact",12,42,6)
        print("x = sprint",12,52,6)
        print("z+x at trolley = phone",12,62,6)
        print("z or x on title = start",12,72,10)

        print("< 2/3 >",48,106,5)
        print("left/right to change",24,116,6)

    elseif title_page == 3 then
        print("tips",54,10,7)

        rectfill(8,24,119,100,0)
        rect(8,24,119,100,7)

        print("watch your energy",14,32,6)
        print("the phone restores energy",14,42,6)
        print("the boss wastes time",14,52,8)
        print("buy upgrades from van",14,62,6)
        print("finish more orders for bonus",14,72,10)

        print("< 3/3 >",48,106,5)
        print("left/right to change",24,116,6)
    end

    return
end

    if day_end then
        draw_day_summary()
        return
    end

    if shop_open then
    draw_shop()
    return
    end
    

    if discipline_active then
        cls(0)

        for l in all(discipline_lines) do
            if discipline_timer > l.delay then
                -- move toward target
                l.x += (l.target_x - l.x) * 0.2

                print(l.text, l.x, l.y, 7)
            end
        end

        -- penalty line (static, always appears)
        if discipline_timer > 80 then
            print("penalty applied", 20, 90, 8)
        end

        return
    end
    cls()
    

    if player_frozen then
        camera(camx + rnd(2)-1, camy + rnd(2)-1)
    else
        camera(camx, camy)
    end

    map(0, 0, 0, 0, 40, 40)

    

    if forklift_active then
    spr(28,forklift_x,forklift_y,2,2)
    end

    draw_debug_arrows()

    spr(crtspr, cx, cy)
    if van_active then
        draw_van(van_x, van_y)
    end
    if stream_hype then
    -- flash on/off
    if stream_flash % 10 < 5 then
        spr(12, cx, cy - 10) -- sprite 012 above cart
    end
    end
    spr(plrspr, px, py)
    
    if forklift_active then
    spr(28,forklift_x,forklift_y,2,2)
    end

    if shadow_state != "idle" then
        draw_shadow(shadow_x, shadow_y)
    end

    if player_frozen and current_line != "" then
        local n = flr(text_progress)

        if n > #current_line then
            n = #current_line
        end

        ?current_line, px - (#current_line * 2), py - 12, 7

        rectfill(
            px - (#current_line * 2) + n * 4,
            py - 12,
            px + (#current_line * 2),
            py - 4,
            0
        )
    end

    if packing then
        rectfill(px-10, py-16, px-10 + pack_progress, py-14, 11)
    end
    draw_arrow_indicator()
        -- van placement debug
    local vx = flr(px/8)*8
    local vy = flr(py/8)*8

    draw_trolley_indicator()

    if checking_phone then
   
    	draw_phone()
    	
    	
	end
    draw_hud()



    
    camera()
    

end

function draw_debug_arrows()
    for a in all(debug_arrows) do
        spr(arrow_sprite(a), a.x, a.y)
    end
    
 
end

-- ===== hud =====

function draw_hud()
    camera()

    rectfill(0,0,127,12,1)

    print("pick:"..order_count,2,2,7)
    print("$"..money,48,2,10)
    print("day:"..day,104,2,7)
    
    local ecolor=11
    if energy_boost_timer>0 then
    ecolor=10
    end

    rectfill(2,9,125,11,5)
    rectfill(2,9,2+energy,11,ecolor)
end

-- ===== shadow draw =====

function draw_shadow(x, y)
    pal()
    palt()

    palt(7, true)
    palt(15, true)
    palt(0, false)

    local spr_id = 39 + shadow_frame
    spr(spr_id, x, y)

    pal()
    palt()
end

function get_clock_time()
    local progress = time_of_day / day_length
    local total_minutes = progress * (shift_hours * 60)

    local hour = shift_start + flr(total_minutes / 60)
    local minute = flr(total_minutes % 60)

    return hour, minute
end

function format_time(h, m)
    if h < 10 then h = "0"..h end
    if m < 10 then m = "0"..m end
    return h..":"..m
end

    function draw_phone()
        camera()


        -- dim background
        rectfill(0,0,127,127,1)

        -- phone frame
        rectfill(20, 16, 108, 124, 0)
        rect(20, 16, 108, 124, 7)

        -- draw video first
        spr(128, 50, 24, 4, 4)
        if stream_hype then
            local txt = "poggies"

            -- draw multiple times for thickness
            print(txt, pog_x, 36, 10)

        end

        -- progress bar over the video
        local prog = 50

        rectfill(50, 50, 82, 54, 5)          -- background
        rectfill(50, 50, 50 + prog/2, 54, 8) -- progress fill

        -- title
        print("lets play: old circle", 24, 71, 7)

        -- channel
        print("live now", 24, 79, 6)

        -- views
        print(viewer_count, 24, 86, 3)
        print("watching", 48,86,6)

        local h, m = get_clock_time()
        local t = format_time(h, m)

        print(t, 80, 18, 7)


        -- hint
        if flr(time()*2)%2==0 then
            print("z+x close", 40, 111, 7)
        end
    end

function complete_order()
    packing = false
    pack_progress = 0

    order_active = false

    local earned = order_total * 10

    money += earned
    day_earnings += earned
    orders_completed_today += 1

    cart_level = 0
    crtspr = 5

    debug_arrows = {}
end

function player_on_tile(tx, ty)
    local px_tile = flr((px + 4) / 8)
    local py_tile = flr((py + 4) / 8)

    return px_tile == tx and py_tile == ty
end

function trolley_near_tile(tx, ty)
    local cx_tile = flr((cx + 4) / 8)
    local cy_tile = flr((cy + 4) / 8)

    return abs(cx_tile - tx) <= 1 and abs(cy_tile - ty) <= 1
end

function draw_van(x, y)
    spr(33, x, y)
    spr(34, x+8, y)
    spr(49, x, y+8)
    spr(50, x+8, y+8)
end


function apply_upgrade(item)

    if item.effect=="energy" then
    energy_boost_timer=1200
    energy = 100

    elseif item.effect=="gloves" then
    if glove_level<3 then
    glove_level+=1
    carry_max=1+glove_level
    shop_items[2].cost+=35
    refresh_shop_items()
    end

    elseif item.effect=="tome" then
    tome_days=1

    elseif item.effect=="magnet" then
    magnet=true

    elseif item.effect=="pto" then
    pto_days+=1

    end

    end

function draw_shop()
    cls(0)

    print("van shop", 50, 10, 7)

    for i=1,#shop_items do
        local item = shop_items[i]
        local y = 30 + i*10

        local col = (i == shop_index) and 11 or 7

        print(item.name.." $"..item.cost, 20, y, col)
    end

    print("money: $"..money, 20, 110, 10)
    print("z=buy  x=exit", 20, 120, 6)
end 

function player_near_van()
    return abs(px - van_x) < 16 and abs(py - van_y) < 16
end

function draw_day_summary()
    cls(0)

    local t = flr(day_summary_timer / 10)

    if t == 0 then
        pal({0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},1)
    elseif t == 1 then
        pal({0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1},1)
    elseif t == 2 then
        pal({0,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2},1)
    else
        pal()
    end

    print("day "..day.." complete",30,16,7)

    print("earnings:",28,42,6)
    print("$"..day_earnings,44,54,11)

    print("performance bonus:",14,72,6)

    if performance_bonus == 0 then
        print("no bonus awarded",24,84,8)
    else
        print("$"..performance_bonus,48,84,10)
    end

    print("total money:",24,102,6)
    print("$"..money,44,114,10)

    if day_summary_timer > 60 then
        print("press z to continue",22,124,7)
    end

    pal()
end

function next_day()

     if pto_days>0 then

    pto_days-=1
    day+=1

    money+=last_day_pay

    day_end=false
    player_frozen=false
    day_summary_timer=0
    day_earnings=0

    return
    end
    day += 1
    time_of_day = 0

    -- end screen off
    day_end = false
    player_frozen = false

    -- money summary reset
    day_earnings = 0
    
    -- order bonus reset
    orders_completed_today = 0

    -- player reset
    px = 100
    py = 240
    pvx = 0
    pvy = 0
    plrspr = 1
    facing = 1
    carrying = false

    -- trolley reset
    cx = 105
    cy = 240
    cvx = 0
    cvy = 0
    cart_level = 0
    crtspr = 5
    grabbing = false
    was_grabbing = false
    grab_timer = 0

    -- energy full
    energy = 100

    -- clear current order state
    order_active = false
    order_count = 0
    debug_arrows = {}
    packing = false
    pack_progress = 0

    -- fresh new order immediately
    spawn_random_arrows(get_order_size())

    -- van reset
    van_active = false
    van_arrived = false
    van_y = 280

    -- misc reset
    checking_phone = false
    stream_hype = false
    stream_timer = 0
    stream_wait = 300 + rnd(300)

    -- camera snap back
    camx = px - 64
    camy = py - 64
end

function player_on_flag(flag)
    local tx = flr((px + 4) / 8)
    local ty = flr((py + 4) / 8)
    return fget(mget(tx, ty), flag)
end

function get_order_size()
    local min_items = min(5, 1 + flr(day/2))
    local max_items = min(10, 3 + day)
    return flr(rnd(max_items - min_items + 1)) + min_items
end

function refresh_shop_items()

 if glove_level==0 then
  shop_items[2].name="gloves"
 elseif glove_level==1 then
  shop_items[2].name="gloves+"
 elseif glove_level==2 then
  shop_items[2].name="gloves++"
 else
  shop_items[2].name="gloves+++"
 end

end

function get_nearest_arrow()
 local nearest=nil
 local best_dist=999999

 for a in all(debug_arrows) do
  local dx=a.x-px
  local dy=a.y-py
  local dist=dx*dx+dy*dy

  if dist<best_dist then
   best_dist=dist
   nearest=a
  end
 end

 return nearest
end

function draw_arrow_indicator()
 if game_state=="title" then return end
 if not order_active then return end
 if #debug_arrows<=0 then return end

 local a=get_nearest_arrow()
 if a==nil then return end

 camera()

 local cx_scr=64
 local cy_scr=64

 local dx=(a.x+4)-px
 local dy=(a.y+4)-py

 local len=sqrt(dx*dx+dy*dy)
 if len<1 then return end

 dx/=len
 dy/=len

 local r=26
 local ix=cx_scr+dx*r
 local iy=cy_scr+dy*r+sin(time()*4)*2

 circfill(ix,iy,3,10)
 circ(ix,iy,4,7)

 -- tiny tail
 line(ix-dx*5,iy-dy*5,ix-dx*9,iy-dy*9,7)
end

function draw_trolley_indicator()
 if game_state=="title" then return end

 camera()

 local sx = cx - camx
 local sy = cy - camy

 -- if trolley already visible, no need
 if sx >= 0 and sx <= 127 and sy >= 0 and sy <= 127 then
  return
 end

 local dx = (cx+4) - px
 local dy = (cy+4) - py

 local len = sqrt(dx*dx + dy*dy)
 if len < 1 then return end

 dx /= len
 dy /= len

 local r = 52

 local ix = 64 + dx*r
 local iy = 64 + dy*r + sin(time()*4)*2

 circfill(ix,iy,4,12)
 circ(ix,iy,5,7)

 -- handle tail
 line(ix-dx*6, iy-dy*6, ix-dx*12, iy-dy*12, 7)


end

function spawn_forklift()
 local spots={}

 for tx=0,39 do
  for ty=0,39 do
   if fget(mget(tx,ty),7) then
    add(spots,{x=tx*8,y=ty*8})
   end
  end
 end

 if #spots<=0 then return end

 local s=spots[flr(rnd(#spots))+1]

 forklift_x=s.x
 forklift_y=s.y

 if rnd(1)<0.5 then
  forklift_vx=1
 else
  forklift_vx=-1
 end

 forklift_active=true
end

function spawn_forklift_right()
forklift_active=true
forklift_just_spawned=true
 local spots={}

 -- right side of map only
 for tx=28,39 do
  for ty=0,39 do

   if fget(mget(tx,ty),7) then
    add(spots,{
     x=tx*8,
     y=ty*8
    })
   end

  end
 end

 if #spots<=0 then return end

 local s=spots[flr(rnd(#spots))+1]

 forklift_x=s.x
 forklift_y=s.y
 forklift_active=true
 forklift_vx=-1

end

function shadow_can_move(tx,ty)
    if tx < 0 or tx > 39 or ty < 0 or ty > 39 then
        return false
    end

    return fget(mget(tx,ty),2)
end

function shadow_node_key(x,y)
    return x + y*64
end

function shadow_reconstruct_first_step(came_from, goal_x, goal_y, start_x, start_y)
    local cx = goal_x
    local cy = goal_y
    local key = shadow_node_key(cx,cy)

    while came_from[key] do
        local prev = came_from[key]

        if prev.x == start_x and prev.y == start_y then
            return cx, cy
        end

        cx = prev.x
        cy = prev.y
        key = shadow_node_key(cx,cy)
    end

    return nil, nil
end

function shadow_find_path_step(start_x, start_y, goal_x, goal_y)
    if start_x == goal_x and start_y == goal_y then
        return nil, nil, true, 0
    end

    local open = {}
    local came_from = {}
    local g_score = {}
    local f_score = {}
    local closed = {}

    local start_key = shadow_node_key(start_x,start_y)
    g_score[start_key] = 0
    f_score[start_key] = abs(goal_x-start_x) + abs(goal_y-start_y)
    add(open, {x=start_x, y=start_y})

    local explored = 0

    while #open > 0 do
    if explored > 80 then
    return nil,nil,false,explored
    end
        local best_i = 1
        local best = open[1]
        local best_key = shadow_node_key(best.x,best.y)
        local best_f = f_score[best_key] or 99999

        for i=2,#open do
            local node = open[i]
            local key = shadow_node_key(node.x,node.y)
            local f = f_score[key] or 99999

            if f < best_f then
                best_i = i
                best = node
                best_key = key
                best_f = f
            end
        end

        deli(open, best_i)
        explored += 1

        if best.x == goal_x and best.y == goal_y then
            local nx, ny = shadow_reconstruct_first_step(came_from, goal_x, goal_y, start_x, start_y)
            return nx, ny, true, explored
        end

        closed[best_key] = true


        local dirs = {
        {1,0},
        {-1,0},
        {0,1},
        {0,-1},

        {1,1},
        {1,-1},
        {-1,1},
        {-1,-1}
    }

        for d in all(dirs) do
            local nx = best.x + d[1]
            local ny = best.y + d[2]
            local nkey = shadow_node_key(nx,ny)

            local can_walk = shadow_can_move(nx,ny)

            -- stop diagonal corner cutting
            if d[1] != 0 and d[2] != 0 then
                can_walk =
                    can_walk and
                    shadow_can_move(best.x + d[1], best.y) and
                    shadow_can_move(best.x, best.y + d[2])
            end

            if can_walk and not closed[nkey] then

                local step_cost = 1
                if d[1] != 0 and d[2] != 0 then
                    step_cost = 1.4
                end

                local tentative_g = (g_score[best_key] or 99999) + step_cost
                local old_g = g_score[nkey]

                if old_g == nil or tentative_g < old_g then
                    came_from[nkey] = {x=best.x, y=best.y}
                    g_score[nkey] = tentative_g
                    f_score[nkey] = tentative_g + abs(goal_x-nx) + abs(goal_y-ny)

                    local already_open = false

                    for node in all(open) do
                        if node.x == nx and node.y == ny then
                            already_open = true
                            break
                        end
                    end

                    if not already_open then
                        add(open,{x=nx,y=ny})
                    end
                end
            end
        end
    end

    return nil, nil, false, explored
end


__gfx__
000000000fff00000fff00000ff000000ff0000000000000000000000000000000000000000a0a00000000000000000000000000000000000000000000000000
00000000fffff000fffff000ffff0000ffff000000000000000000000000000000000000a000000a0000000000000000000a0000000000000000000000000000
00700700f3f3f000fffff000ff9f0000f9ff000000000000000000000000440000004400000044000000440000000000000a0000000000000000000000000000
000770009fff90009fff9000ff99000099ff0000611111160440000004404400044044a0044b44a0044b44a000000000000a0000000000000000000000000000
00077000099900000fff00000aa000000aa00000611111166441111664414416644144a6644b44a6644b44a600000000000a0000000000000000000000000000
00700700fa1af000faaaf0000aff0000ffa000000c6cc6c061111116611111166111111661111116611111160000000000000000000000000000000000000000
000000000ada00000aaa00000aa000000aa00000005005000c6cc6c00c6cc6c00c6cc6c00c6cc6c00c6cc6c000000000000a0000000000000000000000000000
000000000f0f00000f0f00000f00000000f000000000000000500500005005000050050000500500005005000000000000000000000000000000000000000000
00000000fffff00000000000ffff00000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f3f3f00000000000ff9f00000f9ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000009fff900000000000ff990000099ff0000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000
0000000004440000000000000aa4400044aa00000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000
00000000f444f000000000000aff40004ffa00000000000000000000000000000000000000000000000000000000000000060600000000000000000000000000
0000000004440000000000000aa4400044aa00000000000000000000000000000000000000000000000000000000000000060600aaaaa0000000000000000000
000000000f0f0000000000000f000000000f00000000000000000000000000000000000000000000000000000000000000060600a000a0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060600a808a0000000000000000000
00000000000000000000000000000000000000000000000000000000777777777777777707707777770777070000000000060600a000aaaa0000000000000000
000000000000000000000000000000000000000000000000000000007770007707000007000000077700000000000000000606aa0aaa0aaa0000000000000000
0000000000000000000000000000000000000000000000000000000077000007000000000000000000000007000000000006666aa000aaaa0000000000000000
000000000000099999000000000000000000000000000000000000007708080777080800700808007708080700000000666666dddaaaddd00000000000000000
000000000000977777900000000000000000000000000000000000007700000770000007000000070700000000000000000066dddaaaddd00000000000000000
000000000000977777900000000000000000000000000000000000007700000777000000070000007000000000000000666666ddd000ddd00000000000000000
00000000000997777799000000000000000000000000000000000000700000007000000000000000700000000000000000000000000000000000000000000000
00000000000999909999000000000000000000000000000000000000707777700077007070700707000000000000000000000000000000000000000000000000
00000000000990000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000990909999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000990000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000999909099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000999909099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000990000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000999909999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000099999999ddd0dddd99999999777777770000000099999999ddd88ddddddd88ddddddd88dd88ddddddd88ddddddd88dddddd0dddd0000000000000000
0000000074747474ddd0dddd44474747777777770000000099999999dd888dddddd888dddddd888dd888dddddd888dddddd888ddddd0dddd0000000000000000
0000000044444444dd0ddddd74444444777777770000000099999999d8888ddddd8888ddddd8888dd8888ddddd8888ddddd8888ddd0ddddd0000000000000000
0000000044c4c44cdd0dddddc44c4c4477777777000000009999999988888dddd88888dddd88888dd88888dddd88888dddd88888dd0ddddd0000000000000000
0000000044444444ddd0dddd4c44444477777777000000009999999988888dddd88888dddd88888dd88888dddd88888dddd88888ddd0dddd0000000000000000
000000004aa44aa4ddddddddaa444aa4777777770000000099999999d8888ddddd8888ddddd8888dd8888ddddd8888ddddd8888ddddddddd0000000000000000
000000004aa44aa4ddddddddaa444aa4777777770000000099999999dd888dddddd888dddddd888dd888dddddd888dddddd888dddddddddd0000000000000000
0000000099999999dddddddd99999999777777770000000099999999ddd88ddddddd88ddddddd88dd88ddddddd88ddddddd88ddddddddddd0000000000000000
0000000099999999dddddddd999999990000000099999999dddddddddd55dd55dddddddddddddddd000000000000000000000000dddddddddddddddd99999999
0000000044444444dd0ddddd7744444400000000dddddddddddddddddd55dd55dddddddddddddddd000000000000000000000000dd0ddddddddddddddddddddd
0000000047747744dddddddd4444477400000000dddddddddddddddd1111111111111111dddddddd000000000000000000000000dddddddddddddddddddddddd
0000000044444444dddddddd4774444400000000dddddddddddddddddd55dd55dddddddddddddddd000000000000000000000000dddddddddddddddddddddddd
0000000048844444dddddddd8848848800000000dddddddddddddddddd55dd55dddddddddddddddd000000000000000000000000dddddddddddddddddddddddd
0000000048848844ddd0dddd8848848800000000dddddddddddddddd1111111111111111dddddddd000000000000000000000000ddd0dddddddddddddddddddd
0000000044448844ddddd0dd4444444400000000dddddddddddddddddd55dd55dddddddddddddddd000000000000000000000000ddddd0dddddddddddddddddd
0000000099999999dddddd0d9999999900000000dddddddddddddddddd55dd55dddddddddddddddd000000000000000000000000dddddd0ddddddddddddddddd
0000000099999999dddddddd999999990000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000044444474dddddddd444444440000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000044744447ddd0dddd747447440000000000000000dddddddddddddddd0000000000000000000000000000000000000000ddd0dddd0000000000000000
0000000044447444dddddddd444444440000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000041144441dddddddd114441140000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000044441141dddd0ddd441144440000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddd0ddd0000000000000000
0000000044444444dddddddd444441140000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000099999999ddd0dddd999999990000000000000000dddddddddddddddd0000000000000000000000000000000000000000ddd0dddd0000000000000000
0000000099999999dddddddd999999990000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000084444444dddd0ddd444444440000000000000000dddddddddddddddd0000000000000000000000000000000000000000dddd0ddd0000000000000000
0000000044844484dddddddd848448440000000000000000d404dddddddddddd0000000000000000000000000000000000000000dddddddd0000000000000000
0000000044444844dddddddd44444444000000000000000054045555555555550000000000000000000000000000000000000000dddddddd0000000000000000
0000000044444444dddddd0d84844844000000000000000054445555557755770000000000000000000000000000000000000000dddddd0d0000000000000000
0000000074447474dddddddd44444444000000000000000055555555557755770000000000000000000000000000000000000000dddddddd0000000000000000
0000000044744444dd0ddddd4474474400000000000000004dddddd44dddddd40000000000000000000000000000000000000000dd0ddddd0000000000000000
0000000099999999dddddddd9999999900000000000000004dddddd44dddddd40000000000000000000000000000000000000000dddddddd0000000000000000
64646464646464644444444464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000008888888881199999a1911111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000bbbbbbbbb1119991aaaaa910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111999aaa191ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd111ddddd19aaaa11199aaaaa10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd1111ddd11111111111911aaaa1ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd1dddd11ddaaaaadd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddd1111dd11111aaaaaad000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddddd66666666666d11aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666677006666866666555633000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3ddd333b3337700033b3833335555553000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5ddddd3333bddddd3dd4443355555553000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555dd33444db3ddd333d433b33555ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5530034444432222223333333333dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00308043222322233b3333b333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
403003444336633366b3333333333b33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3339933333b663336633333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111117171777177717771717117717171177177711111717177717111711111111111111111111111111111111111111111111111111111
11111111111111111111117171717171717111717171717171711171111111717171117111711111111111111111111111111111111111111111111111111111
11111111111111111111117171777177117711777171717171777177111111777177117111711111111111111111111111111111111111111111111111111111
11111111111111111111117771717171717111717171717171117171111111717171117111711111111111111111111111111111111111111111111111111111
11111111111111111111117771717171717771717177111771771177711111717177717771777111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111fff111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111fffff11111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111f3f3f11111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111611111169fff911111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111611111161999111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111c6cc6c1fa1af11111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111115115111ada111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111f1f111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111aaa1aaa1aaa11aa11aa11111aaa1111111a11111a1a11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111a1a1a1a1a111a111a111111111a111111a111111a1a11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111aaa1aa11aa11aaa1aaa111111a1111111a1111111a111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111a111a1a1a11111a111a11111a11111111a111111a1a11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111a111a1a1aaa1aa11aa111111aaa11111a1111111a1a11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111555151511111155115115151515155515551111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111515151511111511151515151515115115151111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111551155511111555151515151515115115511111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111515111511111115155115551515115115151111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111555155511111551115515551155155515551111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110421010001020202020202040000001104210004048484000000000400000011042100002444000000000004000000110421000021410000000000040000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4646464646464646464646464646464646464646464646464646464646464646464646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51555f634641555f634641555f634641555f634641555f634641555f634641555f4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41525e434641427d434641725e434641625e434641425e434641425e434641565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61565e534661565e534661566d534661566d534661565e534661565e534661565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51525e734651525d734651625e734651525e734651525e734651525e734651564d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41425e634641425e634641426d634641427d634641425d634641426d634641566d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41565e434661565e434661565e434661565e434661565e434661565e434661566d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51525e534651525d534651525e534651525e534651525e534651525e534651564d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61564d414671566d414671564d414671564d414671565d414671564d414671565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51525e434641525e434641565e4346415256434641525d434641525e434641525d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61425e534661425e534661565e5346614256534661425d534661425e534661525d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51565d734651564d734651565d7346515656734651565d734651565e734651725d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41525e634641527d634641425e6346415256634641525d634641526d634641525d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61564d434661565d434661565e434661565e434661565d434661565e434661726d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41565d534651564d534651565d534651565e534651565e534651565d534651567d4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41525e434641524d434641525e434641525e434641525e414671525e434641565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51564d534661565d534661564d534661564d534661724d534661564d534661565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61565e734651564d734651565d734651565e734651625e734651565e734651565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61565e634641525e634641565e634641565e634641625e634641565e634641565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41565e434661524d434661565d434661564d434661625e434661565e434661565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41565e534651565e534651565e534651565e534651427d534651566d534651565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41565e414671565e414671565e414671564d414671625d414671565e414671565e4646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4658585757575858575757585857575758585757575858575757585857575758584646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4659595959666666595959595959596767675959594646464646464646464646464646000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4659595959667666595959595959596777675959594600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4659595959666666595959595959596767675959594600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
270d00120000000200004000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00180004042500b650012500465000650006500025000650006500065000350006500065000650006500005000050000500005000050000500005000050000500005000050000500005000050000500005000050
0010000c0515007150041500615002150061500215006150051500315003150001500065000000000000000000650000000000000000006500000000000000000065000000000000000000650000000000000000
0010000813750105501275010550117500f7501075000450104500f450000000000000000000000b1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002805000050280500005000000000000005000000000000000000000000000000000000000000000000000000000005000050000000000000000000000000000000000000000000000000000000000000
003000202874028740287302872026740267301c7401c7301d7401d7401d7401d7401d7301d7301d7201d72023740237402373023720267402674026730267201c7401c7401c7401c7401c7301c7301c7201c720
0030002000040000400003000030020400203004040040300504005040050300503005020050200502005020070400704007030070300b0400b0400b0300b0300c0400c0400c0300c0300c0200c0200c0200c020
011e00200c505155351853517535135051553518535175350050015535185351a5350050515535185351a53500505155351c5351a53500505155351c5351a53500505155351a5351853500505155351a53518535
010f0020001630020000143002000f655002000020000163001630010000163002000f655001000010000163001630010000163002000f655002000010000163001630f65500163002000f655002000f60300163
013c002000000090750b0750c075090750c0750b0750b0050b0050c0750e075100750e0750c0750b0750000000000090750b0750c0750e0750c0751007510005000000e0751007511075100750c0751007510005
013c00200921409214092140921409214092140421404214022140221402214022140221402214042140421409214092140921409214092140921404214042140221402214022140221402214022140421404214
013c00200521405214052140521404214042140721407214092140921409214092140b2140b214072140721405214052140521405214042140421407214072140921409214092140921409214092140921409214
013c00202150624506285060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01024344
00 01424344
00 02424344
00 03424344
01 09454b08
00 09074a08
00 09070a08
00 0b454c08
02 0a094608

