require "palette"
require "sprites"

-- Geração de objetos
function gerar_virus()
    return {
        x = math.random(5, 475),
        y = math.random(5, 265),
        xv = math.random(1, 2) + math.random(),
        yv = math.random(1, 2) + math.random()
    }
end

function gerar_ponto()
    return {
        x = math.random(2, 478),
        y = math.random(2, 268)
    }
end

-- Inicialização
virus = {gerar_virus()}
ponto = gerar_ponto()
score = 0
estado = 1

pl = {
    x = 10,
    y = 10,
    xv = 0,
    yv = 0,
    atrit = 0.10,
    veloc = 0.10
}

-- Colisão entre o player e um círculo
function colidiu_circulo(x, y, tamanho, cx, cy, raio)
    local px = math.max(x, math.min(cx, x + tamanho))
    local py = math.max(y, math.min(cy, y + tamanho))
    local dx = cx - px
    local dy = cy - py

    return dx * dx + dy * dy <= raio * raio
end

-- Atualização do jogo
function loop(frame)

    -- Movimento do player
    if estado == 1 then
        if not (ui.btn(0) or ui.btn(1) or ui.btn(2) or ui.btn(3)) then
            pl.xv = pl.xv * (1 - pl.atrit)
            pl.yv = pl.yv * (1 - pl.atrit)
        end

        if ui.btn(0) then pl.xv = pl.xv + (-5 - pl.xv) * pl.veloc end
        if ui.btn(1) then pl.xv = pl.xv + (5 - pl.xv) * pl.veloc end
        if ui.btn(2) then pl.yv = pl.yv + (-5 - pl.yv) * pl.veloc end
        if ui.btn(3) then pl.yv = pl.yv + (5 - pl.yv) * pl.veloc end

        pl.x = pl.x + pl.xv
        pl.y = pl.y + pl.yv

        -- Limites do player
        if pl.x < 0 then
            pl.x = 0
            pl.xv = 0
        end
        if pl.x > 470 then
            pl.x = 470
            pl.xv = 0
        end
        if pl.y < 0 then
            pl.y = 0
            pl.yv = 0
        end
        if pl.y > 260 then
            pl.y = 260
            pl.yv = 0
        end

        -- Movimento dos vírus e colisões
        for i = 1, #virus do
            local v = virus[i]

            v.x = v.x + v.xv
            v.y = v.y + v.yv

            -- Paredes
            if v.x < 5 then
                v.x = 5
                v.xv = math.abs(v.xv)
            elseif v.x > 475 then
                v.x = 475
                v.xv = -math.abs(v.xv)
            end

            if v.y < 5 then
                v.y = 5
                v.yv = math.abs(v.yv)
            elseif v.y > 265 then
                v.y = 265
                v.yv = -math.abs(v.yv)
            end

            -- Game over
            if colidiu_circulo(pl.x, pl.y, 10, v.x, v.y, 5) then
                estado = 2
                break
            end
        end

        -- Captura do ponto
        if estado == 1 and
           colidiu_circulo(pl.x, pl.y, 10, ponto.x, ponto.y, 2) then
            ponto = gerar_ponto()
            score = score + 1
            table.insert(virus, gerar_virus())
        end
    end

    -- Paleta
    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end

    -- Renderização
    ui.clip(0, 0, 480, 270)
    ui.camera(0, 0)
    ui.cls(Palette.hex(0x45283c))

    if estado == 1 then
        for i = 1, #virus do
            ui.circfill(
                virus[i].x,
                virus[i].y,
                5,
                Palette.hex(0xFFFFFF)
            )
        end

        ui.circfill(
            ponto.x,
            ponto.y,
            2,
            Palette.hex(0xFFFFFF)
        )

        ui.rectfill(
            pl.x,
            pl.y,
            pl.x + 10,
            pl.y + 10,
            Palette.hex(0xFFFFFF)
        )

        ui.print(
            "score: " .. score,
            32, 32,
            Palette.hex(0xFFFFFF)
        )
    else
        ui.print("game over", 32, 32, Palette.hex(0xFFFFFF))
        ui.print("score: " .. score, 32, 48, Palette.hex(0xFFFFFF))
    end
end
