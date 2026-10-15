require "palette"
require "sprites"
pl={}
pl.x=10
pl.y=10
function loop(frame)
    
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
