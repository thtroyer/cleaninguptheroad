pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--cleaning up the road
--a work in progress

-- global lists
players = {}
trashes = {}
cars = {}

-- timers
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
		 if (trash.x > 5) and (trash.x < 12)
		   and (trash.y > 82) and (trash.y < 88) then
		  del(trashes, trash)
		 end		
		end
 end
end

function move_cars()
 for i,car in pairs(cars) do
  car:move()
  if (car.y < -100) then
   del(cars, car)
  end
 end
end

function spawn_car()
 if (car_timer <= 0) then
  add(cars, car:new())
  car_timer = random(2*30, 3*30)
 end
 car_timer -= 1
end

-- pico-8 hooks
function _init()
 add(players, player:new(10,rnd(5)+10,1))
 add(players, player:new(5,rnd(20)+20,2)) 
 for i = 1,20,1 do
  add(trashes, trash:new())
 end
 
 car_timer = random(1*30, 2*30)

-- add(cars, car:new())
end

function _update()
 handle_controllers()
 is_any_trash_dropped_in_can()
 spawn_car()
 move_cars()
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

function player:new(x,y,sprite_id)
	local o = {}
	setmetatable(o,self)
	self.__index = self
	o.x = x or 10
	o.y = y or 20
	o.dx = 0
	o.dy = 0
	o.is_looking_left = false
	o.sprite_id = sprite_id
	o.trash_obj = nil
	return o
end

function player:draw()
 spr(self.sprite_id, self.x, self.y, 1, 1, self.is_looking_left)
end

function player:move(mov_x, mov_y)
 self.dx = mov_x
 self.dy = mov_y
 
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

-->8
-- trash object
trash = {}

function trash:new()
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
	
	o.x = random_int(23,45)
	o.y = -20
	o.sprite_id = 14 -- 12
	o.dy = 3
	o.moving_up = random_int(1,2) == 1
-- 	log(o.moving_up)
	
	if o.moving_up then
	 o.dy = -3
  o.y = 128
	 o.x = random_int(67,73)
	end
	
	return o
end

function car:move()
 self.y += self.dy
end

function car:draw()
 if self.moving_up then
  spr(self.sprite_id, self.x, self.y)
  spr(self.sprite_id+1, self.x+8, self.y)
  spr(self.sprite_id+16, self.x, self.y+8)
  spr(self.sprite_id+17, self.x+8, self.y+8)
  spr(self.sprite_id+32, self.x, self.y+16)
  spr(self.sprite_id+33, self.x+8, self.y+16)
  spr(self.sprite_id+48, self.x, self.y+24)
  spr(self.sprite_id+49, self.x+8, self.y+24) 
 else
  spr(self.sprite_id, self.x, self.y)
  spr(self.sprite_id+1, self.x+8, self.y)
  spr(self.sprite_id+16, self.x, self.y+8)
  spr(self.sprite_id+17, self.x+8, self.y+8)
  spr(self.sprite_id+32, self.x, self.y+16)
  spr(self.sprite_id+33, self.x+8, self.y+16)
  spr(self.sprite_id+48, self.x, self.y+24)
  spr(self.sprite_id+49, self.x+8, self.y+24)  
 end
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
555555555555555555577555555555550000000000000000000a0a00000000000000000000000000000000000000000011111111111161111111111111116111
5557755555555555555775555555555500000000000000000000a000000000000000000000000000000000000000000011111111111111111111111111111111
555775555555555555577555555555550000000000000000011a1110000000000000000000000000000000000000000031111111111111138111111111111118
55577555555555555557755577777777000000000000000011111111000000000000000000000000000000000000000033333333333333338888888888888888
5557755555555555555775557777777700000000000000001111161100000000000000000000000000000000000000003133333333bbbb138188888888eeee18
55577555555555555557755555555555000000000000000011111111000000000000000000000000000000000000000031333333333333138188888888888818
55577555555555555557755555555555000000000000000011111111000000000000000000000000000000000000000031333333333333138188888888888818
55555555555555555557755555555555000000000000000001111110000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbbbbbbbbbbbbbbb3bbbbbbbbabbb00000000000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbb3bbbbbbbbbbbb3bbbbbbbaaabb00000000000000000000000000000000000000000000000031333333333333138188888888888818
6666666666666666bbbbbb3bbbbbbbbbbbbbbb3bbbbb3bbb00000000000000000000000000000000000000000000000031333333333333138188888888888818
5555555566666666b3bbbbbbbbbbb3bbb3bbbb3bbbb333bb00000000000000000000000000000000000000000000000033133333333331338818888888888188
6666666666666666b3bbbbbbbbbbb3bbb3bbbbbbbbbb3bbb00000000000000000000000000000000000000000000000013333333333333311888888888888881
6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000013311111111113311881111111111881
6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000013111111111111311811111111111181
00000000333333336000000600000000000000000000000000000000000000000000000000000000000000000000000013311111111113311881111111111881
00000000311111136011110600000000000000000000000000000000000000000000000000000000000000000000000033333333333333338888888888888888
0000000031111113a011110600000000000000000000000000000000000000000000000000000000000000000000000033333333333333338888888888888888
0000000033333336a000000600000000000000000000000000000000000000000000000000000000000000000000000033333333333333338888888888888888
00000000333333360000050000000000000000000000000000000000000000000000000000000000000000000000000003993333333399300899888888889980
00000000555333360000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333330000008888888888000
000000005a5333360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555333366000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555554445555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555544ff5555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
66666666666666666666666655577555555555555555554ff45555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555454ff5555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555554545885855555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555455888555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555111555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555551551555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbabbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbaaabbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbb3bbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb333bbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbb3bbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbbbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbbbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbbbb3bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbbb3bbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbabbbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbaaabbbbb3bbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbb3bbbbbbbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbb3bb3bbbbbbbbb333bbb3bbbb3b
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555b3bbbbbbb3bbbbbbbbbb3bbbb3bbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbb3bbbbbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbb3bb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555b3bbbbbbb3bbbbbbb3bbbbbbbbbbb3bb
666666666666666666666666555775555555555555555555555555555557755555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
666666666666666666666666555775555555555555555555555555555555555555555555555555555555555555577555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

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
000100200070001700017000170001700067000070006700107000e7000d7000f700167001c700207002b7002e700307003770000700017000b70001700007000170000700007000070000700007000170001700
0601000032700307002f7102c7202a73029740267502475021750217501f7501c7501d7401b7201772014720107200f7200973007760047500174000740017500075007750017500075000750007000070000700
04010000000000272404734077440b7440d7440f75410754117501375414754157441574015740167401c7401c740227302e730327501b7001c7001d700007001a700227002470026700297002d7002e70000000
