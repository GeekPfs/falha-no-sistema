require "palette"
require "sprites"
pl={}
pl.x=10
pl.y=10
pl.xv=0
pl.yv=0
pl.xvd=0
pl.yvd=0
function loop(frame)
    pl.x = pl.x + pl.xv
    pl.y = pl.y + pl.yv
    pl.xv = pl.xv + ((0-pl.xv)*0.5)
    pl.yv = pl.yv + ((0-pl.yv)*0.5)
    if ui.btn(0) then pl.xv = pl.xv + ((5-pl.xv)*0.5) end
    if ui.btn(1) then pl.xv = pl.xv + ((5-pl.xv)*0.5) end
    if ui.btn(2) then pl.yv = pl.yv + ((-5-pl.yv)*0.5) end
    if ui.btn(3) then pl.yv = pl.yv + ((-5-pl.yv)*0.5) end
    
    for i = 1, #Palette do
        local color = Palette[i]
        ui.palset(i - 1, color)
    end
    
    ui.clip(0,0,480,270)
    ui.camera(0,0)
    ui.cls(Palette.hex(0x45283c))
    
    ui.print("Oi, Lupi td bem?", 32, 32, Palette.hex(0xFFFFFF))
    ui.rectfill(pl.x, pl.y, pl.x+10, pl.y+10, Palette.hex(0xFFFFFF))
end 
