require "palette"
require "sprites"

function gerar_virus()
    return 
    x = math.random(0,480),
    y = math.random(0,270),
    
end

virus={}
virus[1]=gerar_virus()
pl={}
pl.x=10
pl.y=10
pl.xv=0
pl.yv=0

pl.atrit=0.10
pl.veloc=0.10
function loop(frame)

    
    
    pl.x = pl.x + pl.xv
    pl.y = pl.y + pl.yv
    if not (ui.btn(0) or ui.btn(1) or ui.btn(2) or ui.btn(3)) then 
        pl.xv = pl.xv + ((0-pl.xv)*pl.atrit)
        pl.yv = pl.yv + ((0-pl.yv)*pl.atrit)
    end
    
    if ui.btn(0) then pl.xv = pl.xv + ((-5-pl.xv)*pl.veloc) end
    if ui.btn(1) then pl.xv = pl.xv + ((5-pl.xv)*pl.veloc) end
    if ui.btn(2) then pl.yv = pl.yv + ((-5-pl.yv)*pl.veloc) end
    if ui.btn(3) then pl.yv = pl.yv + ((5-pl.yv)*pl.veloc) end
    
    for i = 1, #Palette do
        local color = Palette[i]
        ui.palset(i - 1, color)
    end
    
    ui.clip(0,0,480,270)
    ui.camera(0,0)
    ui.cls(Palette.hex(0x45283c))
    ui.circfill(virus[1].x,virus[1].y,5,Palette.hex(0xFFFFFF))
    ui.print("Oi, Lupi td bem?", 32, 32, Palette.hex(0xFFFFFF))
    ui.rectfill(pl.x, pl.y, pl.x+10, pl.y+10, Palette.hex(0xFFFFFF))
end 
