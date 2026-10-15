
require "palette"
require "sprites"

-- ==========================================
-- CONFIGURACAO
-- ==========================================

LARGURA = 480
ALTURA = 270
FPS = 60

FUNDO = 0x160F25
BRANCO = 0xFFFFFF
CIANO = 0x48F0E0
ROXO = 0xB56AFF
ROSA = 0xFF5C9A
AMARELO = 0xFFE66D
VERMELHO = 0xFF5263

CORES = {
    0x48F0E0,
    0xB56AFF,
    0xFF5C9A,
    0xFFE66D,
    0x6DAAFF
}

-- ==========================================
-- FUNCOES AUXILIARES
-- ==========================================

function aleatoria_cor()
    return CORES[math.random(1, #CORES)]
end

function distancia(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function limitar(v, minimo, maximo)
    return math.max(minimo, math.min(v, maximo))
end

function gerar_virus()
    return {
        x = math.random(10, 470),
        y = math.random(10, 260),
        xv = (math.random(1, 2) + math.random()) *
            (math.random(0, 1) == 0 and -1 or 1),
        yv = (math.random(1, 2) + math.random()) *
            (math.random(0, 1) == 0 and -1 or 1),
        cor = aleatoria_cor(),
        fase = math.random(0, 100)
    }
end

function gerar_ponto()
    return {
        x = math.random(12, 468),
        y = math.random(12, 258),
        cor = aleatoria_cor(),
        fase = 0
    }
end

function criar_particula(x, y, cor, quantidade, forca)
    for i = 1, quantidade do
        local angulo = math.random() * math.pi * 2
        local velocidade = math.random() * forca

        table.insert(particulas, {
            x = x,
            y = y,
            xv = math.cos(angulo) * velocidade,
            yv = math.sin(angulo) * velocidade,
            vida = math.random(12, 28),
            vida_max = 28,
            cor = cor,
            tamanho = math.random(1, 3)
        })
    end
end

function explosao(x, y, cor)
    criar_particula(x, y, cor, 20, 3)
    criar_particula(x, y, BRANCO, 7, 2)
    tremor = math.max(tremor, 4)
end

function criar_rastro(x, y, cor, tamanho)
    table.insert(rastro, {
        x = x,
        y = y,
        vida = 12,
        tamanho = tamanho,
        cor = cor
    })

    if #rastro > 45 then
        table.remove(rastro, 1)
    end
end

-- ==========================================
-- ESTADO DO JOGO
-- ==========================================

function reiniciar()
    virus = {}
    virus[1] = gerar_virus()

    ponto = gerar_ponto()
    particulas = {}
    rastro = {}

    score = 0
    combo = 0
    melhor_combo = 0

    combo_timer = 0
    overdrive = 0
    tremor = 0
    tempo_jogo = 0

    pl = {
        x = 240,
        y = 135,
        xv = 0,
        yv = 0,
        atrit = 0.10,
        veloc = 0.10,
        dash = 12,
        dx = 1,
        dy = 0,
        cor = CIANO,
        anim = 0
    }

    estado = 1
end

reiniciar()

-- ==========================================
-- COLETAR PONTO
-- ==========================================

function coletar_ponto()
    score = score + 1
    combo = combo + 1
    combo_timer = 300

    if combo > melhor_combo then
        melhor_combo = combo
    end

    explosao(ponto.x, ponto.y, ponto.cor)

    ponto = gerar_ponto()

    -- Cada ponto cria um novo virus.
    table.insert(virus, gerar_virus())

    -- Ativa o modo especial ao atingir 10.
    if combo >= 10 and overdrive <= 0 then
        overdrive = 300
        tremor = 8

        criar_particula(
            pl.x + 5, pl.y + 5, AMARELO, 45, 5
        )
    end
end

-- ==========================================
-- ATUALIZAR PARTICULAS
-- ==========================================

function atualizar_efeitos()
    for i = #particulas, 1, -1 do
        local p = particulas[i]

        p.x = p.x + p.xv
        p.y = p.y + p.yv
        p.xv = p.xv * 0.96
        p.yv = p.yv * 0.96
        p.vida = p.vida - 1

        if p.vida <= 0 then
            table.remove(particulas, i)
        end
    end

    for i = #rastro, 1, -1 do
        local p = rastro[i]

        p.vida = p.vida - 1

        if p.vida <= 0 then
            table.remove(rastro, i)
        end
    end

    if tremor > 0 then
        tremor = tremor * 0.75

        if tremor < 0.3 then
            tremor = 0
        end
    end
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================

function loop(frame)

    atualizar_efeitos()

    if estado == 1 then

        tempo_jogo = tempo_jogo + 1
        pl.anim = pl.anim + 1

        if combo_timer > 0 then
            combo_timer = combo_timer - 1

            if combo_timer <= 0 then
                combo = 0
            end
        end

        if overdrive > 0 then
            overdrive = overdrive - 1

            if overdrive <= 0 then
                combo = 0
                combo_timer = 0
            end
        end

        -- Movimento
        pl.x = pl.x + pl.xv
        pl.y = pl.y + pl.yv

        -- Dash na direcao do movimento.
        if ui.btnp(4) then
            local dx = pl.xv
            local dy = pl.yv
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist > 0.1 then
                pl.xv = (dx / dist) * pl.dash
                pl.yv = (dy / dist) * pl.dash
            else
                pl.xv = pl.dx * pl.dash
                pl.yv = pl.dy * pl.dash
            end

            criar_particula(
                pl.x + 5, pl.y + 5, pl.cor, 15, 3
            )
            tremor = math.max(tremor, 2)
        end

        -- Limites da tela
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

        -- Atrito
        if not (
            ui.btn(0) or ui.btn(1) or
            ui.btn(2) or ui.btn(3)
        ) then
            pl.xv = pl.xv * (1 - pl.atrit)
            pl.yv = pl.yv * (1 - pl.atrit)
        end

        -- Controles direcionais
        if ui.btn(0) then
            pl.xv = pl.xv + (-5 - pl.xv) * pl.veloc
            pl.dx = -1
            pl.dy = 0
        end

        if ui.btn(1) then
            pl.xv = pl.xv + (5 - pl.xv) * pl.veloc
            pl.dx = 1
            pl.dy = 0
        end

        if ui.btn(2) then
            pl.yv = pl.yv + (-5 - pl.yv) * pl.veloc
            pl.dx = 0
            pl.dy = -1
        end

        if ui.btn(3) then
            pl.yv = pl.yv + (5 - pl.yv) * pl.veloc
            pl.dx = 0
            pl.dy = 1
        end

        -- Rastro do jogador
        if tempo_jogo % 2 == 0 then
            local cor = pl.cor

            if overdrive > 0 then
                cor = AMARELO
            end

            criar_rastro(
                pl.x + 5,
                pl.y + 5,
                cor,
                overdrive > 0 and 5 or 3
            )
        end

        -- Movimento dos virus
        for i = 1, #virus do
            local v = virus[i]

            v.x = v.x + v.xv
            v.y = v.y + v.yv
            v.fase = v.fase + 1

            if v.x > 475 then
                v.x = 475
                v.xv = -math.abs(v.xv)
            end

            if v.x < 5 then
                v.x = 5
                v.xv = math.abs(v.xv)
            end

            if v.y > 265 then
                v.y = 265
                v.yv = -math.abs(v.yv)
            end

            if v.y < 5 then
                v.y = 5
                v.yv = math.abs(v.yv)
            end
        end

        -- Coleta do ponto
        if distancia(
            pl.x + 5, pl.y + 5,
            ponto.x, ponto.y
        ) < 10 then
            coletar_ponto()
        end

        -- Colisoes com os virus.
        -- No overdrive, os virus sao coletados.
        for i = #virus, 1, -1 do
            local v = virus[i]

            if distancia(
                pl.x + 5, pl.y + 5,
                v.x, v.y
            ) < 11 then

                if overdrive > 0 then
                    score = score + 1

                    explosao(v.x, v.y, v.cor)

                    table.remove(virus, i)
                else
                    explosao(pl.x + 5, pl.y + 5, VERMELHO)
                    estado = 2
                    break
                end
            end
        end

    elseif estado == 2 then

        -- Reiniciar somente ao pressionar o botao.
        if ui.btnp(4) then
            reiniciar()
        end

    end

    -- ======================================
    -- RENDERIZACAO
    -- ======================================

    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end

    ui.clip(0, 0, LARGURA, ALTURA)

    local shake_x = 0
    local shake_y = 0

    if tremor > 0 then
        shake_x = math.random(
            -math.floor(tremor),
            math.floor(tremor)
        )

        shake_y = math.random(
            -math.floor(tremor),
            math.floor(tremor)
        )
    end

    ui.camera(0, 0)
    ui.cls(Palette.hex(FUNDO))

    -- Pontos decorativos de fundo
    for i = 1, 35 do
        local x = (i * 137) % LARGURA
        local y = (i * 79) % ALTURA

        ui.circfill(
            x, y, 1,
            Palette.hex(0x40314F)
        )
    end

    -- Tremor afeta o mundo, nao a interface.
    ui.camera(shake_x, shake_y)

    -- Rastro da bola
    for i = 1, #rastro do
        local p = rastro[i]
        local tamanho = math.max(
            1,
            math.floor(p.tamanho * p.vida / 12)
        )

        ui.circfill(
            p.x, p.y, tamanho + 2,
            Palette.hex(0x40314F)
        )

        ui.circfill(
            p.x, p.y, tamanho,
            Palette.hex(p.cor)
        )
    end

    if estado == 1 then

        -- Ponto: halo e nucleo.
        ui.circfill(
            ponto.x, ponto.y, 7,
            Palette.hex(0x40314F)
        )

        ui.circfill(
            ponto.x, ponto.y, 4,
            Palette.hex(ponto.cor)
        )

        ui.circfill(
            ponto.x, ponto.y, 2,
            Palette.hex(BRANCO)
        )

        -- Virus coloridos.
        for i = 1, #virus do
            local v = virus[i]

            ui.circfill(
                v.x, v.y, 7,
                Palette.hex(0x40314F)
            )

            ui.circfill(
                v.x, v.y, 5,
                Palette.hex(v.cor)
            )

            ui.circfill(
                v.x - 1, v.y - 1, 2,
                Palette.hex(BRANCO)
            )
        end

        -- Jogador: esfera luminosa.
        local px = pl.x + 5
        local py = pl.y + 5
        local cor_jogador = pl.cor

        if overdrive > 0 then
            cor_jogador = AMARELO
        end

        ui.circfill(
            px, py, 10,
            Palette.hex(0x40314F)
        )

        ui.circfill(
            px, py, 7,
            Palette.hex(cor_jogador)
        )

        ui.circfill(
            px - 2, py - 2, 3,
            Palette.hex(BRANCO)
        )

        if overdrive > 0 then
            ui.circfill(
                px, py, 12,
                Palette.hex(AMARELO)
            )

            ui.circfill(
                px, py, 7,
                Palette.hex(AMARELO)
            )

            ui.circfill(
                px - 2, py - 2, 3,
                Palette.hex(BRANCO)
            )
        end

    end

    -- Particulas por cima do mundo.
    for i = 1, #particulas do
        local p = particulas[i]

        ui.circfill(
            p.x, p.y,
            math.max(1, p.tamanho),
            Palette.hex(p.cor)
        )
    end

    -- Interface sem tremor.
    ui.camera(0, 0)

    if estado == 1 then

        -- Painel superior
        ui.rectfill(
            10, 10, 135, 35,
            Palette.hex(0x29203C)
        )

        ui.print(
            "SCORE  " .. score,
            18, 19,
            Palette.hex(BRANCO)
        )

        -- Combo
        if combo > 1 then
            local cor_combo = CIANO

            if combo >= 7 then
                cor_combo = ROSA
            end

            if combo >= 10 then
                cor_combo = AMARELO
            end

            ui.print(
                "COMBO x" .. combo,
                160, 19,
                Palette.hex(cor_combo)
            )

            local largura = math.floor(
                60 * combo_timer / 300
            )

            ui.rectfill(
                160, 31, 220, 34,
                Palette.hex(0x40314F)
            )

            if largura > 0 then
                ui.rectfill(
                    160, 31, 160 + largura, 34,
                    Palette.hex(cor_combo)
                )
            end
        end

        -- Medidor do overdrive
        if overdrive > 0 then
            ui.rectfill(
                290, 10, 465, 35,
                Palette.hex(0x40314F)
            )

            ui.print(
                "OVERDRIVE!",
                302, 15,
                Palette.hex(AMARELO)
            )

            local largura = math.floor(
                165 * overdrive / 300
            )

            ui.rectfill(
                295, 29, 295 + largura, 32,
                Palette.hex(AMARELO)
            )
        else
            ui.print(
                "10 COMBOS = OVERDRIVE",
                290, 19,
                Palette.hex(0xA99ABF)
            )
        end

        ui.print(
            "DASH: BOTAO 5",
            10, 252,
            Palette.hex(0xA99ABF)
        )

    elseif estado == 2 then

        -- Game over
        ui.rectfill(
            65, 35, 415, 235,
            Palette.hex(0x29203C)
        )

        ui.rectfill(
            70, 40, 410, 230,
            Palette.hex(FUNDO)
        )

        ui.print(
            "GAME OVER",
            181, 66,
            Palette.hex(ROSA)
        )

        ui.print(
            "SCORE FINAL",
            188, 100,
            Palette.hex(0xA99ABF)
        )

        ui.print(
            tostring(score),
            225, 120,
            Palette.hex(BRANCO)
        )

        ui.print(
            "MELHOR COMBO: x" .. melhor_combo,
            157, 150,
            Palette.hex(CIANO)
        )

        ui.print(
            "APERTE DASH PARA REINICIAR",
            130, 192,
            Palette.hex(AMARELO)
        )

    end
end
