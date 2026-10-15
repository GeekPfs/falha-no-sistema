
require "palette"
require "sprites"

function gerar_virus()
    return {
        x = math.random(0, 480),
        y = math.random(0, 270),
        xv = math.random(1,2) + math.random(),
        yv = math.random(1,2) + math.random()
    }
end

function gerar_ponto()
    return {
        x = math.random(0, 480),
        y = math.random(0, 270)
    }
end

virus = {}
virus[1] = gerar_virus()
ponto = gerar_ponto()
score = 0
pl = {}
pl.x = 10
pl.y = 10
pl.xv = 0
pl.yv = 0

pl.atrit = 0.10
pl.veloc = 0.10

function loop(frame)
    pl.x = pl.x + pl.xv
    pl.y = pl.y + pl.yv


    if pl.x < 0 then pl.x = 0 pl.xv = 0 end
    if pl.x > 470 then pl.x = 470 pl.xv = 0 end
    
    if pl.y < 0 then pl.y = 0 pl.yv = 0 end
    if pl.y > 260 then pl.y = 260 pl.yv = 0 end
    
    if not (ui.btn(0) or ui.btn(1) or ui.btn(2) or ui.btn(3)) then
        pl.xv = pl.xv + ((0 - pl.xv) * pl.atrit)
        pl.yv = pl.yv + ((0 - pl.yv) * pl.atrit)
    end

    if ui.btn(0) then pl.xv = pl.xv + ((-5 - pl.xv) * pl.veloc) end
    if ui.btn(1) then pl.xv = pl.xv + ((5 - pl.xv) * pl.veloc) end
    if ui.btn(2) then pl.yv = pl.yv + ((-5 - pl.yv) * pl.veloc) end
    if ui.btn(3) then pl.yv = pl.yv + ((5 - pl.yv) * pl.veloc) end


    for i=1, #virus do
        virus[i].x = virus[i].x + virus[i].xv
        virus[i].y = virus[i].y + virus[i].yv
        if virus[i].x > 480 then virus[i].xv = -virus[i].xv end
        if virus[i].x < 0 then virus[i].xv = -virus[i].xv end
        if virus[i].y > 270 then virus[i].yv = -virus[i].yv end
        if virus[i].y < 0 then virus[i].yv = -virus[i].yv end
    end


    if pl.x < ponto.x + 10 and pl.x + 10 > ponto.x and pl.y < ponto.y + 10 and pl.y + 10 > ponto.y then
        ponto=gerar_ponto()
        score=score+1
        table.insert(virus,gerar_virus())
    end
    for i = 1, #Palette do
        local color = Palette[i]
        ui.palset(i - 1, color)
    end

    ui.clip(0, 0, 480, 270)
    ui.camera(0, 0)
    ui.cls(Palette.hex(0x45283c))
    for i=1,#virus do
        ui.circfill(virus[i].x, virus[i].y, 5, Palette.hex(0xFFFFFF))
    end
    ui.circfill(ponto.x, ponto.y, 2, Palette.hex(0xFFFFFF))
    ui.print("score: "..score, 32, 32, Palette.hex(0xFFFFFF))
    ui.rectfill(pl.x, pl.y, pl.x + 10, pl.y + 10, Palette.hex(0xFFFFFF))
end

