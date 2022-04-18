-- title:  flappy bird
-- author: Dante
-- desc:   flappy bird hecho en tic80
-- script: lua

t=0

mapx=0

player={
	pos={
		x=50,
		y=32
	},
	motionY=0,
	sprite=38,
	gravity=0.17,
	jump=2.5,
	dead=false,
	inPipe=false,
	active=false,
	points=0
}

--funcion de collision 
function player:collision(flag)
	
	local collided = false
	--pocicion del jugador en el siguiente frame
	local newpos={
		x=(self.pos.x+mapx)%480,
		y=(self.pos.y+self.motionY+2)%480
	}
	--alto y ancho del jugador para obtener las esquinas
	local offset={
		x=(newpos.x+16)%480,
		y=(newpos.y+11)%480
	}
	
	--convierto las cordenadas de las esquinas del jugador
	--en cordenadas de mapa (8 pixeles = 1 cuadrante de mapa)
	--y luego obtengo el sprite que esta en ese cuadrante
	local maptiles={
	                mget(newpos.x/8,newpos.y/8),
	                mget(newpos.x/8,offset.y/8),
	                mget(offset.x/8,offset.y/8),
	                mget(offset.x/8,newpos.y/8)
	               }
	--voy 1 por 1 por los elementos de la lista maptiles
	--y me fijo si tiene la flag
	for i,v in ipairs(maptiles) do 
		collided = fget(v,flag) or collided
	end
	return collided
	
end

--la pocision en la memoria de todos lo sprites que
--forman las distintas partes de las tuberias
pipe={
	top={
		{2,3,4,5},
		{18,19,20,21}
	},
	mid={{34,35,36,37}},
	bottom={
		{50,51,52,53},
		{66,67,68,69}
		}
}


--funcion que se encarga de agregar una parte de las 
--tuberias
--
--en el parametro part se debe ingresar la parte de la 
--tuberia que se quiere agregar al mapa 
--pipe.top , pipe.mid o pipe.bottom
function pipe:draw(x,y,part)
	
	for tileY,c in ipairs(part) do 
		for tileX, tile in ipairs(c) do 
			mset((x+tileX-1)%60,y+tileY-1,tile)
		end
	end
end


--funcion que se encarga de crear las tuberias
function pipe:drawComplete(x)
	math.randomseed(time()+tstamp())
	local pipepos=math.random(2,8)
	pipe:draw(x,pipepos-2, pipe.bottom)
	for i=pipepos-3,0,-1 do
		pipe:draw(x,i,pipe.mid)
	end
	
	for i=pipepos,pipepos+5,1 do
		mset(x+1,i,1)
		mset(x+2,i,1)
	end
	
	pipe:draw(x,pipepos+5, pipe.top)
	
	for i=pipepos+7,14,1 do
		pipe:draw(x,i,pipe.mid)
	end
	
end


--funcion que imprime texto con sombra
function printShadow(text,x,y,color,fixed,scale,smallfont,shadowoffset,shadowcolor)
	
	--valores default
	x=x or 0
	y=y or 0
	color = color or 12
	fixed = fixed or false
	scale = scale or 1
	smallfont = smallfont or false
	shadowoffset = shadowoffset or 1
	shadowcolor = shadowcolor or 0
	
	print(text,x+shadowoffset,y+shadowoffset,shadowcolor,fixed,scale,smallfont)
	print(text,x,y,color,fixed,scale,smallfont)
	
end

function TIC()
	t=t+1
	cls()
	map(0,0,60,17,-mapx,0)
	map(0,0,60,17,-mapx+60*8,0)
	-- jugador
	if not player.dead and player.active then
		
		--movimiento de map
		mapx=(mapx+1)%(60*8)
		--gravedad
		player.motionY = player.motionY + player.gravity
		
		--salto
		if btnp(0) then
			player.motionY = -player.jump
			sfx(0)
		end
		
		--collision
		if player:collision(0) or player.pos.y < -16 then
			player.dead = true
			player.motionY=0
			sfx(2)
		end
		
		--contado de puntos
		if player:collision(1) then
			player.inPipe=true
		elseif player.inPipe and not player:collision(1) then
			player.points=player.points+1
			player.inPipe=false
			sfx(1)
		end
		
		--movimieto
		player.pos.y = player.pos.y + player.motionY
		
		--animacion
		player.sprite = ((math.floor(t*0.1))%3)*2+38
		
		--generacio de mapa
		for i=0,14,1 do
		mset(((mapx+280)/8)%60,i,0)
		end
	
		if t%(80) == 0 then
			pipe:drawComplete(((mapx+240)%(60*8))/8)
		end
		
		
		--pantalla de inicio
	elseif not player.active then
		
		mapx=(mapx+1)%(60*8)
		
		player.pos.y=math.sin(t*0.1)*6+40
		local textwidth = print("press up to start",0,-6)
		printShadow("press up to start",(240-textwidth)//2,(136-6)//2)
		if btnp(0) then
			sfx(0)
			player.pos.y=math.floor(player.pos.y)
		 player.motionY = -player.jump
			player.active=true
		end
		player.sprite = ((math.floor(t*0.1))%3)*2+38
		
		--pantalla de final
	else
		textwidth = print("you lose",0,-6)
		printShadow("you lose",(240-textwidth)//2,(136-6)//2)
		deatht=deatht or t
		if btnp(0) and t>deatht+30  then
		 reset()
		end
	end
	
	--imprimir jugador
	spr(player.sprite,player.pos.x,player.pos.y,11,1,0,0,2,2)
	
	--imprimir puntos
	textwidth = print(player.points,0,-12,12,false,2)
	--printShadow(player.points,(240-textWidth)//2+1,25+1,15,false,2)
	printShadow(player.points,(240-textwidth)//2,25,12,false,2)
	
	--debug
	--print(player.inPipe)
	--print(player.pos.x,0,7)
	--print(player.pos.y,20,7)
	--print(mapx,0,14)
	--print(player.sprite,0,21)
	--print(deatht,0,28)
	--print(t,0,35)
	--
	--if btnp(4) then
	--	pipe:drawComplete(((mapx+240)%(60*8))/8)
	--end
	
end

-- <TILES>
-- 000:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 001:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 002:0000000005555555066665550556655505566555055665550556655505566555
-- 003:0000000055555555555566665555655655556556555565565555655655556556
-- 004:0000000055555555666666666666666666666666666666666666666666666666
-- 005:0000000055555550666666606565655066565550656565506656555065656550
-- 006:0000000066655556665555666555566655556666777777773333333344444444
-- 016:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 017:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 018:05566555055665550556655505566555055665550556655500000000bb000000
-- 019:5555655655556556555565565555655655556556555565560000000000000000
-- 020:6666666666666666666666666666666666666666666666660000000000000000
-- 021:66565550656565506656555065656550665655506565655000000000000000bb
-- 022:4444444444444444444444444444444444444444444444444444444444444444
-- 032:bbbbbbbbbbbbbbbbbbbbbb00bbbb00ccbbb0cc44bb0c4444b0444444b0444444
-- 033:bbbbbbbbbbbbbbbb0000bbbbc0cc0bbb0cccc0bb0ccc0c0b0ccc0c0b40cccc0b
-- 034:bb055566bb055566bb055566bb055566bb055566bb055566bb055566bb055566
-- 035:5555565555555655555556555555565555555655555556555555565555555655
-- 036:6666666666666665666666666666666566666666666666656666666666666665
-- 037:565550bb656550bb565550bb656550bb565550bb656550bb565550bb656550bb
-- 038:bbbbbbbbbbbbbbbbbbbbbb00bbbb00ccbbb0cc44bb0c4444b0444444b0444444
-- 039:bbbbbbbbbbbbbbbb0000bbbbc0cc0bbb0cccc0bb0ccc0c0b0ccc0c0b40cccc0b
-- 040:bbbbbbbbbbbbbbbbbbbbbb00bbbb00ccbbb0cc44bb0c4444b0444444b0000044
-- 041:bbbbbbbbbbbbbbbb0000bbbbc0cc0bbb0cccc0bb0ccc0c0b0ccc0c0b40cccc0b
-- 042:bbbbbbbbbbbbbbbbbbbbbb00bbbb00ccbbb0cc44b00004440cccc0440ccccc04
-- 043:bbbbbbbbbbbbbbbb0000bbbbc0cc0bbb0cccc0bb0ccc0c0b0ccc0c0b40cccc0b
-- 048:b000004404ccc4040cccc0330cc40333b0000333bbbbb000bbbbbbbbbbbbbbbb
-- 049:44000000402222200200000b3022220b330000bb00bbbbbbbbbbbbbbbbbbbbbb
-- 050:bb00000000000000055665550556655505566555055665550556655505566555
-- 051:0000000000000000555565565555655655556556555565565555655655556556
-- 052:0000000000000000666666666666666666666666666666666666666666666666
-- 053:000000bb00000000656565506656555065656550665655506565655066565550
-- 054:b000004404ccc4040cccc0330cc40333b0000333bbbbb000bbbbbbbbbbbbbbbb
-- 055:44000000402222200200000b3022220b330000bb00bbbbbbbbbbbbbbbbbbbbbb
-- 056:0ccccc0404ccc404b0000033bb033333bbb00333bbbbb000bbbbbbbbbbbbbbbb
-- 057:44000000402222200200000b3022220b330000bb00bbbbbbbbbbbbbbbbbbbbbb
-- 058:04ccc404b0444044bb000333bb033333bbb00333bbbbb000bbbbbbbbbbbbbbbb
-- 059:44000000402222200200000b3022220b330000bb00bbbbbbbbbbbbbbbbbbbbbb
-- 066:0556655505566555055665550556655505566555066665550555555500000000
-- 067:5555655655556556555565565555655655556556555566665555555500000000
-- 068:6666666666666666666666666666666666666666666666665555555500000000
-- 069:6565655066565550656565506656555065656550666666605555555000000000
-- </TILES>

-- <MAP>
-- 015:606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:8200720062005200520042004200420042004200320032003200320032003200320032003200420042005200620082009200a200b200c200e200f200324000000000
-- 001:6002700390048006000700072007400370139012c001c001e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000412000000000
-- 002:020d020e020e020f02000200320052007200b200d200d200d200e200e200e200e200e200e200e200f200f200f200f200f200f200f200f200f200f200215000000000
-- </SFX>

-- <FLAGS>
-- 000:00201010101010000000000000000000000010101010100000000000000000000000101010100000000000000000000000001010101000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

