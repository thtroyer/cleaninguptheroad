pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--cleaning up the road
--a work in progress

-- global lists
players = {}
trashes = {}
cars = {}

-- global timers
car_timer = nil

-- utility methods
function random(minimum, maximum)
	return rnd(maximum-minimum) + minimum
end

function random_int(low, high)
	return flr(rnd(high+1-low))+low
end

function log(msg)
	printh(msg, "log.txt", false)
end

function debug(msg)
	print(msg, 20, 20, 7)
end

function handle_controllers()
	for i,player in pairs(players) do
		local mov_x = 0
		if(btn(⬅️,i-1)) then
			mov_x = -1
			elseif(btn(➡️,i-1)) then
			mov_x = 1
		end

		local mov_y = 0
		if(btn(⬆️,i-1)) then mov_y = -1
		elseif(btn(⬇️,i-1)) then mov_y = 1 end

		player:move(mov_x, mov_y)

		if(btnp(❎,i-1)) then
			player:pickup(trashes)
		end
	end
end

function is_any_trash_dropped_in_can()
	for i,trash in pairs(trashes) do
		local is_held = false
		for j,player in pairs(players) do
			if trash == player.trash_obj then
				is_held = true
			end
		end
		
		if not is_held then
			if (trash.x > 5) and (trash.x < 12) and (trash.y > 82) and (trash.y < 88) then
			del(trashes, trash)
			end
		end
	end
end

function move_cars()
	for i,car in pairs(cars) do
		car:move()
		if car:should_destroy() then
			del(cars, car)
		end
	end
end

function spawn_car()
	if (car_timer <= 0) then
		add(cars, car:new())
		car_timer = random(5*30, 20*30)
	end
	car_timer -= 1
end

-- recursive
function create_a_trash()
	t = trash:new()
	
		--avoid generating in top right
	if t.x < 20 and t.y < 20 then
		return create_a_trash()
	end
	
	-- prefer generating trash beside road
	if t.x > 20 and t.x < 104 then
		if random_int(0,100) > 5 then
			return create_a_trash()
		end
	end
	return t
end

function trash_gen(c)
	for i = 1,c,1 do
		add(trashes, create_a_trash())
	end
end

-- pico-8 hooks
function _init()
	add(players, player:new(10,rnd(5)+10,1))
	add(players, player:new(5,rnd(20)+20,2)) 
	trash_gen(20)

	car_timer = random(1*30, 3*30)
	music(0)
end

function cars_collision()
	for _,car in pairs(cars) do
		car:collide(players)
	end
end

function _update()
	handle_controllers()
	is_any_trash_dropped_in_can()
	spawn_car()
	move_cars()
	cars_collision()
end

function _draw()
	cls()
	map()
	foreach(trashes, function(o) o:draw() end)
	foreach(players, function(o) o:draw() end)
	foreach(cars, function(o) o:draw() end)
end

-->8
-- player object
player = {}

function player:new(x,y,player_id)
	local o = {}
	setmetatable(o,self)
	self.__index = self
	o.x = x or 10
	o.y = y or 20
	o.dx = 0
	o.dy = 0
	o.is_looking_left = false
	o.trash_obj = nil
	o.walk_timer = nil
	o.walk_state = 0
	o.hearts = 3
	o.player_id = player_id
	o.hit_timer = nil
	o.flicker = false
	
	o.sprite_id = 55
	if(player_id == 1) then
		o.sprite_id = 52
	end
	return o
end

function player:draw()
	self:countdown_timer()
	
	if (self.hearts <= 0) then
		return
	end
	
	sprite_id = self.sprite_id
	if (self.walk_state == 1) then
		sprite_id += 1
	elseif (self.walk_state == 3) then
		sprite_id += 2
	end
	
	if not (self.hit_timer == nil) then
		self.flicker = not self.flicker
		if (self.flicker == false) then
			spr(sprite_id, self.x, self.y, 1, 1, self.is_looking_left)
		end
	else
		spr(sprite_id, self.x, self.y, 1, 1, self.is_looking_left)	
	end
	self:draw_hearts()
end

function player:countdown_timer()
	-- countdown hit timer
	if not (self.hit_timer == nil) then
		self.hit_timer -= 1
		if (self.hit_timer <= 0) then
			self.hit_timer = nil
			self.flicker = false
		end
	end
end

function player:move(mov_x, mov_y)
	
	if (mov_x == 0 and mov_y == 0) then
		self.walk_timer = nil
		self.walk_state = 0
		return
	end
	
	if (self.walk_timer == nil) then
		self.walk_timer = 5
	end
	if (self.walk_timer == 0) then
		self.walk_timer = 5
		self.walk_state += 1
		if self.walk_state > 3 then
			self.walk_state = 0
		end
	end
	
	if not (self.hit_timer == nil) then
		self.dx = mov_x * 0.3
		self.dy = mov_y * 0.3
	else
		self.dx = mov_x
		self.dy = mov_y
	end

	if (mov_x == 1) then
		self.is_looking_left = false
	elseif (mov_x == -1) then
		self.is_looking_left = true
	end

	self.x += self.dx
	self.y += self.dy

	if self.trash_obj != nil then
		if self.is_looking_left then
			self.trash_obj.x = self.x - 6
		else
			self.trash_obj.x = self.x + 6
		end
		self.trash_obj.y = self.y + 2
	end
	
	self.walk_timer -= 1
	
	-- boundries
	if self.y > 130 then
		self.y = 130
	elseif self.y < -8 then 
		self.y = -8
	end
	
	if self.x > 130 then
		self.x = 130
	elseif self.x < -8 then 
		self.x = -8
	end
end

function player:pickup(trashes)
	if (self.trash_obj != nil) then
		self.trash_obj = nil
		sfx(1)
		return
	end

	for i,trash in pairs(trashes) do
		if (trash.x > (self.x-8)) and (trash.x < (self.x+8)) then
			if (trash.y > (self.y-8)) and (trash.y < (self.y+8)) then
				self.trash_obj = trash
				sfx(2)
				break
			end
		end
	end
end

function player:run_over()
	if self.hit_timer == nil then
		sfx(3)
		self.hit_timer = 150
		self.hearts -= 1
	end
end

function player:draw_hearts()
	spr(24+self.player_id, 0, (self.player_id * 10) - 7)
	for i = 1,self.hearts,1 do
		spr(24, 7 + ((i-1)*5), (self.player_id * 8)-8 + 3)
	end
end

-->8
-- trash object
trash = {}

function trash:new(x, y)
	local o = {}
	setmetatable(o,self)
	self.__index = self
	
	o.x = rnd(115) + 5
	o.y = rnd(115) + 5
	o.sprite_id = rnd(7)+3
	o.is_recyclable = false
	
	return o
end

function trash:draw()
	spr(self.sprite_id, self.x, self.y)
end


-->8
-- car object
car = {}

function car:new()
	local o = {}
	setmetatable(o,self)
	self.__index = self
	
	sprite_rng = random_int(1,2)
	if (sprite_rng == 1) then
		o.sprite_id = 12
	else
		o.sprite_id = 14
	end
	
	o.moving_up = random_int(1,2) == 1
	
	if o.moving_up then
		o.dy = -3
		o.y = 250
		o.x = random_int(67,73)
	else
	o.x = random_int(28,43)
	o.y = -200
	o.dy = 3
	
	end
	
	return o
end

function car:move()
	self.y += self.dy
end

function car:draw()
	if self.moving_up then
		spr(self.sprite_id, self.x, self.y, 2, 4)
		if (self.y > 128+20 and self.y < 128+40)
				or (self.y > 128+60 and self.y < 128+80)
				or (self.y > 128+100 and self.y < 128+120) then
			rectfill(40, 120, 80, 121, 8)
		end
	else
		spr(self.sprite_id, self.x, self.y, 2, 4, false, true)
		if (self.y < -20-48 and self.y > -40-48)
				or(self.y < -60-48 and self.y > -80-48)
				or(self.y < -100-48 and self.y > -120-48) then
			rectfill(40, 5, 80, 6, 8)
		end
	end
end

function car:collide(players)
	for i,player in pairs(players) do
	
		if (player.x+8 > self.x) and (self.x+16 > player.x) then
			if (player.y+5 > self.y) and (self.y+31 > player.y) then
				player:run_over()
			end
		end
	end
end

function car:should_destroy()
	if self.moving_up then
		return (self.y < -50)
	end
	return (self.y > 150)
end

__gfx__
00000000000444000088008800000000000000000000000000000000000000000000000000000000000000000000000000003333333300000000888888880000
000000000044ff00008e88e800000000000000000000000000000000000000000000000000000000000000000000000000333333333333000088888888888800
00700700004ff1000008ee1000000000000000000000000000067000000000000000000000000000000000000000000003663333333366300866888888886680
000770000404ff000008ee80068ee70000aaa000000ccc00007677000008e00000eee000000dd00000000000000000003a333333333333a38a888888888888a8
000770004040880800008e0806888600009aa000000ccc0007767000000880000088e000001ddd00000000000000000033333333333333338888888888888888
007007000400888000008e8005288600000900000001cc0000dd6000000880000000000000010000000000000000000033333333333333338888888888888888
0000000000001110000088e000000000000000000000000000000000000000000000000000000000000000000000000033331111111133338888111111118888
00000000000100100008008000000000000000000000000000000000000000000000000000000000000000000000000013111111111111311811111111111181
555555555555555555577555555555550000000000000000000a0a00000000000000000000000000088000880000000011111111111161111111111111116111
5557755555555555555775555555555500000000000000000000a00000000000000000000004440008e888e80000000011111111111111111111111111111111
555775555555555555577555555555550000000000000000011a11100000000000000000004fff40008eee800000000031111111111111138111111111111118
55577555555555555557755577777777000000000000000011111111000000000000000004f5f5f408e1e1e80000000033333333333333338888888888888888
55577555555555555557755577777777000000000000000011111611000000000008080004fffff408ee8ee8000000003133333333bbbb138188888888eeee18
5557755555555555555775555555555500000000000000001111111100000000008e878004f888f408eeeee80000000031333333333333138188888888888818
55577555555555555557755555555555000000000000000011111111000000000008e800040fff04008eee800000000031333333333333138188888888888818
55555555555555555557755555555555000000000000000001111110000000000000800004000004000000000000000031333333333333138188888888888818
6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbbbbbbbbbbbbbbb3bbbbbbbbabbb00000000000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbb3bbbbbbbbbbbb3bbbbbbbaaabb00000000000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbb3bbbbbbbbbbbbbbb3bbbbb3bbb00000000000000000000000000000000000000000000000031333333333333138188888888888818
5555555566666666b3bbbbbbbbbbb3bbb3bbbb3bbbb333bb00000000000000000000000000000000000000000000000033133333333331338818888888888188
6666666666666666b3bbbbbbbbbbb3bbb3bbbbbbbbbb3bbb00000000000000000000000000000000000000000000000013333333333333311888888888888881
6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000013311111111113311881111111111881
6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000013111111111111311811111111111181
00000000333333336000000600000000000444000004440000044400008800880088008800880088000000000000000013311111111113311881111111111881
000000003111111360111106000000000044ff000044ff000044ff00008e88e8008e88e8008e88e8000000000000000033333333333333338888888888888888
0000000031111113a011110600000000004ff100004ff100004ff1000008ee100008ee100008ee10000000000000000033333333333333338888888888888888
0000000033333336a0000006000000000404ff000404ff000404ff000008ee800008ee800008ee80000000000000000033333333333333338888888888888888
0000000033333336000005000000000040408808404088084040880800008e0800008e0800008e08000000000000000003993333333399300899888888889980
0000000055533336000000000000000004008880040088800400888000008e8000008e8000008e80000000000000000000033333333330000008888888888000
000000005a5333360000000000000000000011100000111000001110000088e0000088e0000088e0000000000000000000000000000000000000000000000000
00000000555333366000000600000000000010100001001000001001000080800008008000008008000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888228228888228822888222822888888822888888ff8888
88888f8f8f8f88828282828888888888888888888888888888888888888888888888888888888888882288822888222222888222822888882282888888fff888
88888f8f8f8f88888888888888888888888888888888888888888888888888888888888888888888882288822888282282888222888888228882888888f88888
88888f8f8f8f888282828288888888888888888888888888888888888888888888888888888888888822888228882222228888882228882288828888fff88888
88888f8f8f8f88888888888888888888888888888888888888888888888888888888888888888888882288822888822228888228222888882282888ffff88888
88888f8f8f8f88828282828888888888888888888888888888888888888888888888888888888888888228228888828828888228222888888822888fff888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555850505055550505050555505050505555050505055550505050555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555557777777775566666666655666666666556666666665566666666655555555555555555555555555555555555
555566656665666566656665666566555555e55575557555755655565566556555655565565556555655655565656555e555555555c555555555555555555555
55556565656556555655655565656565555ee55575757575755656566566556565666565565656665655656565656555ee55555555cc55555c55c55511115555
5555666566655655565566556655656555eee55575757575755656566566556565655565565656655655656565556555eee5555cccccc555cc55c55511115555
55556555656556555655655565656565555ee55575757575755656566566556565656665565656665655656566656555ee55555c00cc055cccccc55511115555
555565556565565556556665656565655555e55575557555755655565556556555655565565556555655655566656555e555555c55c05550cc00055511115555
55555555555555555555555555555555555555557777777775566666666655666666666556666666665566666666655555555550550555550c55555500005555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555055555555555555
55555555555555555555555555555555555555555d67676d55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555515555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555171555555555555555
55555555555500000000055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555171151555555555555
555556666655066606660555555d5555555566666555555555555555555555555556666655555555555555555555555555666665555555171717155555555555
55555655565506060606055555d5d555555565556555555555555555555555555556555655555555555555555555555555655565555551177777155555555555
5555565756550606066605555d5d5555555565556555555555555555555555555556555655555555555555555555555555655565555517177777155555555555
555556555655060606060555d5d55555555565556555555555555555555555555556555655555555555555555555555555655565555551777777155555555555
555556666655066606660555dd555555555566666555555555555555555555555556666655555555555555555555555555666665555555117771555555555555
55555555555500000000055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555517771555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551115555555555555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550a1aaa1aaa1aaaa1aaaa1aaaa1aa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
5550aaaaaaaaaaaaaaaaaaaaaaaaaaa0550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55505050505050505050505050505050550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507700000066600eee00ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070000000600e0e00c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070000066600e0e00ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507070000060000e0e0000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc000d000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507770000066600eee00ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507000000000600e0e00c000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507700000066600e0e00ccc0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507000000060000e0e0000c0000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55507000000066600eee00ccc000d000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500100010001000010000100001000550555555555555555555555555555055055555555555555555555555555505505555555555555555555555555550555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__map__
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020201211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020201211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020201211111110111111122522222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2132211211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020201211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111111111111122422252400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121211211111110111111122422222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100200d0500f0500d0500f05001700067000070006700107000e7000d7000f700167001c700207002b7002e700307003770000700017000b70001700007000170000700007000070000700007000170001700
0601000032700307002f7102c7202a73029740267502475021750217501f7501c7501d7401b7201772014720107200f7200973007760047500174000740017500075007750017500075000750007000070000700
04010000000000272404734077440b7440d7440f75410754117501375414754157441574015740167401c7401c740227302e730327501b7001c7001d700007001a700227002470026700297002d7002e70000000
030100000040000400024500245003450034500345004450034500345000400004000040000400004000040001400014000140002400024000240002400014500145001450014500145001450014500145000400
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1910000018010000001c010000001c0101c00018010000001c0101c0151c00000000000000000000000000001a010000001d010000001d010000001a010000001d0101d015000000000000000000000000000000
__music__
03 08424344

