
require "palette"
require "sprites"


CFG = {
    LARGURA=480, ALTURA=270, FPS=60,

    FUNDO=0x080609, FUNDO_PAINEL=0x180B10,
    VERMELHO=0xFF243F, VERMELHO_ESCURO=0x781426,
    VERMELHO_CLARO=0xFF6174, VERDE=0x45FF78,
    VERDE_ESCURO=0x126B36, BRANCO=0xF5F0F0,
    CINZA=0x88777D, AMARELO=0xFFE66D,

    PLAYER_RAIO=5, PLAYER_ACELERACAO=0.10,
    PLAYER_ATRITO=0.10, PLAYER_VELOCIDADE_MAX=5,
    PLAYER_DASH_VELOCIDADE=20, PLAYER_DASH_COOLDOWN=0,

    VIRUS_INICIAIS=1, VIRUS_POR_PONTO=1, VIRUS_RAIO=5,
    VIRUS_VEL_INICIAL_MIN=1.5, VIRUS_VEL_INICIAL_MAX=2.5,
    VIRUS_VEL_MAX=5.0, VIRUS_AUMENTO_VEL=0.20,
    VIRUS_INTERVALO_AUMENTO=5,

    COMBO_TEMPO=5, COMBO_PARA_OVERDRIVE=5,
    OVERDRIVE_TEMPO=5, OVERDRIVE_PONTOS_POR_VIRUS=1,

    PARTICULAS_COLETA=24, PARTICULAS_EXPLOSAO=35,
    RASTRO_LIMITE=40, RASTRO_FREQUENCIA=2,
    SCANLINES=true, SCANLINE_INTERVALO=3,
    GLITCH_ATIVO=true, GLITCH_FREQUENCIA=0.08,
    GLITCH_BLOCOS=5, TREMOR_MAX=7,

    INTRO_TEXTO="VIRUS INVADIU O SISTEMA...",
    INTRO_TEXTO_2="SOBREVIVA.", INTRO_VELOCIDADE=2,
    INTRO_ESPERA=75, MOSTRAR_CONTROLES=true
}

function cor(hex) return Palette.hex(hex) end
function limitar(v,min,max) return math.max(min,math.min(v,max)) end

function distancia(x1,y1,x2,y2)
    local dx,dy=x2-x1,y2-y1
    return math.sqrt(dx*dx+dy*dy)
end

function aleatoria_cor_virus()
    local cores={CFG.VERMELHO,CFG.VERMELHO_CLARO,CFG.VERMELHO_ESCURO}
    return cores[math.random(1,#cores)]
end

function velocidade_aleatoria()
    return CFG.VIRUS_VEL_INICIAL_MIN+math.random()*
        (CFG.VIRUS_VEL_INICIAL_MAX-CFG.VIRUS_VEL_INICIAL_MIN)
end

function gerar_virus()
    local angulo=math.random()*math.pi*2
    local vel=velocidade_aleatoria()
    return {
        x=math.random(12,CFG.LARGURA-12),
        y=math.random(12,CFG.ALTURA-12),
        xv=math.cos(angulo)*vel, yv=math.sin(angulo)*vel,
        cor=aleatoria_cor_virus(), fase=math.random(0,100),
        pulso=math.random(0,100)
    }
end

function gerar_ponto()
    return {
        x=math.random(12,CFG.LARGURA-12),
        y=math.random(20,CFG.ALTURA-12),
        fase=0, cor=CFG.VERDE
    }
end

function gerar_jogador()
    return {
        x=CFG.LARGURA/2, y=CFG.ALTURA/2,
        xv=0, yv=0, dx=1, dy=0, anim=0,
        dash_cooldown=0
    }
end


estado=0
virus_do_capeta={}
particulas={}
rastro={}
glitches={}
pl=gerar_jogador()
ponto=gerar_ponto()
score=0
combo=0
melhor_combo=0
combo_timer=0
overdrive=0
tremidinha=0
tempo_jogo=0
tempo_aumento_virus=0
velocidade_virus_atual=CFG.VIRUS_VEL_INICIAL_MIN
intro_indice=0
intro_indice_2=0
intro_espera=0
intro_finalizada=false
menu_anim=0
gameover_anim=0
recorde_sessao=0
frame_atual=0
glitch_timer=0


function criar_particula(x,y,corzinha,qtd,forca)
    for i=1,qtd do
        local a=math.random()*math.pi*2
        local v=math.random()*forca
        table.insert(particulas,{
            x=x,y=y,xv=math.cos(a)*v,yv=math.sin(a)*v,
            vida=math.random(10,28),vida_max=28,
            cor=corzinha,tamanho=math.random(1,3)
        })
    end
end

function criar_rastro(x,y,corzinha,tamanho)
    table.insert(rastro,{x=x,y=y,vida=12,tamanho=tamanho,cor=corzinha})
    while #rastro>CFG.RASTRO_LIMITE do table.remove(rastro,1) end
end

function explosao(x,y,corzinha)
    criar_particula(x,y,corzinha,CFG.PARTICULAS_EXPLOSAO,4)
    criar_particula(x,y,CFG.BRANCO,8,2)
    tremidinha=math.max(tremidinha,CFG.TREMOR_MAX)
end

function atualizar_efeitos()
    for i=#particulas,1,-1 do
        local p=particulas[i]
        p.x=p.x+p.xv; p.y=p.y+p.yv
        p.xv=p.xv*0.96; p.yv=p.yv*0.96
        p.vida=p.vida-1
        if p.vida<=0 then table.remove(particulas,i) end
    end

    for i=#rastro,1,-1 do
        rastro[i].vida=rastro[i].vida-1
        if rastro[i].vida<=0 then table.remove(rastro,i) end
    end

    if tremidinha>0 then
        tremidinha=tremidinha*0.72
        if tremidinha<0.3 then tremidinha=0 end
    end
end

function gerar_glitch()
    glitches={}
    for i=1,CFG.GLITCH_BLOCOS do
        table.insert(glitches,{
            x=math.random(0,CFG.LARGURA-1),
            y=math.random(0,CFG.ALTURA-1),
            w=math.random(5,65),h=math.random(1,5),
            cor=math.random(0,1)==0 and CFG.VERMELHO or CFG.VERDE
        })
    end
end


function iniciar_jogo()
    virus_do_capeta={}; particulas={}; rastro={}; glitches={}
    pl=gerar_jogador(); ponto=gerar_ponto()

    for i=1,CFG.VIRUS_INICIAIS do
        table.insert(virus_do_capeta,gerar_virus())
    end

    score=0; combo=0; melhor_combo=0
    combo_timer=0; overdrive=0; tremidinha=0
    tempo_jogo=0; tempo_aumento_virus=0
    velocidade_virus_atual=CFG.VIRUS_VEL_INICIAL_MIN
    gameover_anim=0
    estado=1
end


function coletar_ponto()
    score=score+1
    combo=combo+1
    combo_timer=math.floor(CFG.COMBO_TEMPO*CFG.FPS)
    melhor_combo=math.max(combo,melhor_combo)
    recorde_sessao=math.max(score,recorde_sessao)

    explosao(ponto.x,ponto.y,CFG.VERDE)
    criar_particula(ponto.x,ponto.y,CFG.VERDE_ESCURO,12,2)

    for i=1,CFG.VIRUS_POR_PONTO do
        table.insert(virus_do_capeta,gerar_virus())
    end

    ponto=gerar_ponto()

    if combo>=CFG.COMBO_PARA_OVERDRIVE and overdrive<=0 then
        overdrive=math.floor(CFG.OVERDRIVE_TEMPO*CFG.FPS)
        tremidinha=CFG.TREMOR_MAX
        criar_particula(pl.x,pl.y,CFG.VERDE,50,5)
    end
end

function aumentar_velocidade_virus()
    for i=1,#virus_do_capeta do
        local v=virus_do_capeta[i]
        local vel=math.sqrt(v.xv*v.xv+v.yv*v.yv)
        if vel>0 then
            local nova=math.min(vel+CFG.VIRUS_AUMENTO_VEL,CFG.VIRUS_VEL_MAX)
            v.xv=v.xv/vel*nova
            v.yv=v.yv/vel*nova
        end
    end
end

function atualizar_virus()
    for i=1,#virus_do_capeta do
        local v=virus_do_capeta[i]
        v.x=v.x+v.xv; v.y=v.y+v.yv
        v.fase=v.fase+1; v.pulso=v.pulso+1

        if v.x>CFG.LARGURA-CFG.VIRUS_RAIO then
            v.x=CFG.LARGURA-CFG.VIRUS_RAIO
            v.xv=-math.abs(v.xv)
        end
        if v.x<CFG.VIRUS_RAIO then
            v.x=CFG.VIRUS_RAIO
            v.xv=math.abs(v.xv)
        end
        if v.y>CFG.ALTURA-CFG.VIRUS_RAIO then
            v.y=CFG.ALTURA-CFG.VIRUS_RAIO
            v.yv=-math.abs(v.yv)
        end
        if v.y<CFG.VIRUS_RAIO then
            v.y=CFG.VIRUS_RAIO
            v.yv=math.abs(v.yv)
        end
    end
end


function atualizar_jogo()
    tempo_jogo=tempo_jogo+1
    tempo_aumento_virus=tempo_aumento_virus+1

    local intervalo=math.max(1,math.floor(CFG.VIRUS_INTERVALO_AUMENTO*CFG.FPS))
    if tempo_aumento_virus>=intervalo then
        tempo_aumento_virus=0
        aumentar_velocidade_virus()
    end

    if combo_timer>0 then
        combo_timer=combo_timer-1
        if combo_timer<=0 then combo=0 end
    end

    if overdrive>0 then
        overdrive=overdrive-1
        if overdrive<=0 then combo=0; combo_timer=0 end
    end

    if pl.dash_cooldown>0 then pl.dash_cooldown=pl.dash_cooldown-1 end
    pl.anim=pl.anim+1
    pl.x=pl.x+pl.xv; pl.y=pl.y+pl.yv

    if not (ui.btn(0) or ui.btn(1) or ui.btn(2) or ui.btn(3)) then
        pl.xv=pl.xv*(1-CFG.PLAYER_ATRITO)
        pl.yv=pl.yv*(1-CFG.PLAYER_ATRITO)
    end

    if ui.btn(0) then
        pl.xv=pl.xv-CFG.PLAYER_ACELERACAO*(CFG.PLAYER_VELOCIDADE_MAX+pl.xv)
        pl.dx=-1; pl.dy=0
    end
    if ui.btn(1) then
        pl.xv=pl.xv+CFG.PLAYER_ACELERACAO*(CFG.PLAYER_VELOCIDADE_MAX-pl.xv)
        pl.dx=1; pl.dy=0
    end
    if ui.btn(2) then
        pl.yv=pl.yv-CFG.PLAYER_ACELERACAO*(CFG.PLAYER_VELOCIDADE_MAX+pl.yv)
        pl.dx=0; pl.dy=-1
    end
    if ui.btn(3) then
        pl.yv=pl.yv+CFG.PLAYER_ACELERACAO*(CFG.PLAYER_VELOCIDADE_MAX-pl.yv)
        pl.dx=0; pl.dy=1
    end

    local vel=math.sqrt(pl.xv*pl.xv+pl.yv*pl.yv)
    if vel>CFG.PLAYER_VELOCIDADE_MAX then
        pl.xv=pl.xv/vel*CFG.PLAYER_VELOCIDADE_MAX
        pl.yv=pl.yv/vel*CFG.PLAYER_VELOCIDADE_MAX
    end

    if ui.btnp(4) and pl.dash_cooldown<=0 then
        local dx,dy=pl.xv,pl.yv
        local dist=math.sqrt(dx*dx+dy*dy)
        if dist>0.1 then
            pl.xv=dx/dist*CFG.PLAYER_DASH_VELOCIDADE
            pl.yv=dy/dist*CFG.PLAYER_DASH_VELOCIDADE
        else
            pl.xv=pl.dx*CFG.PLAYER_DASH_VELOCIDADE
            pl.yv=pl.dy*CFG.PLAYER_DASH_VELOCIDADE
        end
        pl.dash_cooldown=math.floor(CFG.PLAYER_DASH_COOLDOWN*CFG.FPS)
        criar_particula(pl.x,pl.y,CFG.VERMELHO_CLARO,20,3)
        tremidinha=math.max(tremidinha,2)
    end

    pl.x=limitar(pl.x,0,CFG.LARGURA-10)
    pl.y=limitar(pl.y,0,CFG.ALTURA-10)

    if tempo_jogo%math.max(1,CFG.RASTRO_FREQUENCIA)==0 then
        criar_rastro(pl.x+5,pl.y+5,overdrive>0 and CFG.VERDE or CFG.VERMELHO,
            overdrive>0 and 5 or 3)
    end

    atualizar_virus()

    if distancia(pl.x+5,pl.y+5,ponto.x,ponto.y)<CFG.PLAYER_RAIO+4 then
        coletar_ponto()
    end

    for i=#virus_do_capeta,1,-1 do
        local v=virus_do_capeta[i]
        if distancia(pl.x+5,pl.y+5,v.x,v.y)<CFG.PLAYER_RAIO+CFG.VIRUS_RAIO then
            if overdrive>0 then
                score=score+CFG.OVERDRIVE_PONTOS_POR_VIRUS
                recorde_sessao=math.max(score,recorde_sessao)
                explosao(v.x,v.y,CFG.VERDE)
                table.remove(virus_do_capeta,i)
            else
                explosao(pl.x+5,pl.y+5,CFG.VERMELHO)
                estado=2
                break
            end
        end
    end
end

function desenhar_fundo()
    ui.cls(cor(CFG.FUNDO))
    for i=1,45 do
        local x=(i*137)%CFG.LARGURA
        local y=(i*79)%CFG.ALTURA
        ui.rectfill(x,y,x+1,y+1,cor(CFG.VERMELHO_ESCURO))
    end

    if CFG.SCANLINES then
        for y=0,CFG.ALTURA,CFG.SCANLINE_INTERVALO do
            ui.rectfill(0,y,CFG.LARGURA,y,cor(0x160B10))
        end
    end

    if CFG.GLITCH_ATIVO then
        if math.random()<CFG.GLITCH_FREQUENCIA then gerar_glitch() end
        for i=1,#glitches do
            local g=glitches[i]
            ui.rectfill(g.x,g.y,math.min(CFG.LARGURA,g.x+g.w),
                math.min(CFG.ALTURA,g.y+g.h),cor(g.cor))
        end
    end
end

function desenhar_rastro()
    for i=1,#rastro do
        local p=rastro[i]
        local tamanho=math.max(1,math.floor(p.tamanho*p.vida/12))
        ui.circfill(p.x+2,p.y,tamanho+1,cor(CFG.VERMELHO_ESCURO))
        ui.circfill(p.x,p.y,tamanho,cor(p.cor))
    end
end

function desenhar_particulas()
    for i=1,#particulas do
        local p=particulas[i]
        ui.rectfill(p.x,p.y,p.x+p.tamanho,p.y+p.tamanho,cor(p.cor))
    end
end

function desenhar_jogador()
    local x,y=pl.x+5,pl.y+5
    local c=overdrive>0 and CFG.VERDE or CFG.VERMELHO_CLARO

    ui.circfill(x-2,y,CFG.PLAYER_RAIO+2,cor(CFG.VERMELHO_ESCURO))
    ui.circfill(x+2,y,CFG.PLAYER_RAIO,cor(CFG.VERMELHO))
    ui.circfill(x,y,CFG.PLAYER_RAIO-1,cor(c))
    ui.circfill(x-1,y-2,2,cor(CFG.BRANCO))

    if frame_atual%7<2 then
        ui.rectfill(x-8,y-1,x+9,y,cor(CFG.VERMELHO_CLARO))
    end
end

function desenhar_ponto()
    local x,y=ponto.x,ponto.y
    ui.circfill(x,y,9,cor(CFG.VERDE_ESCURO))
    ui.circfill(x,y,6,cor(CFG.VERDE))
    ui.circfill(x,y,3,cor(CFG.BRANCO))
    ui.rectfill(x-10,y,x-7,y+1,cor(CFG.VERDE))
    ui.rectfill(x+7,y,x+10,y+1,cor(CFG.VERDE))

    if frame_atual%9<3 then
        ui.rectfill(x-5,y-8,x+5,y-7,cor(CFG.VERDE))
    end
end

function desenhar_virus()
    for i=1,#virus_do_capeta do
        local v=virus_do_capeta[i]
        ui.circfill(v.x+2,v.y,CFG.VIRUS_RAIO+3,cor(CFG.VERMELHO_ESCURO))
        ui.circfill(v.x,v.y,CFG.VIRUS_RAIO,cor(v.cor))
        ui.circfill(v.x-1,v.y-1,2,cor(CFG.BRANCO))

        if v.fase%13<3 then
            ui.rectfill(v.x-8,v.y-1,v.x+9,v.y,cor(CFG.VERMELHO_CLARO))
        end
    end
end

function desenhar_hud()
    ui.rectfill(8,8,139,36,cor(CFG.FUNDO_PAINEL))
    ui.rectfill(8,8,11,36,cor(CFG.VERMELHO))
    ui.print("SCORE",18,12,cor(CFG.CINZA))
    ui.print(tostring(score),18,22,cor(CFG.BRANCO))

    if combo>0 then
        local c=combo>=CFG.COMBO_PARA_OVERDRIVE and CFG.VERDE or CFG.VERMELHO_CLARO
        ui.print("COMBO x"..combo,160,14,cor(c))

        local total=math.max(1,CFG.COMBO_TEMPO*CFG.FPS)
        local largura=math.floor(70*combo_timer/total)
        ui.rectfill(160,27,230,30,cor(CFG.VERMELHO_ESCURO))
        if largura>0 then ui.rectfill(160,27,160+largura,30,cor(c)) end
    end

    if overdrive>0 then
        ui.rectfill(300,8,471,36,cor(CFG.VERDE_ESCURO))
        ui.print("SYSTEM OVERRIDE",308,12,cor(CFG.VERDE))
        ui.print("ACTIVE",308,23,cor(CFG.BRANCO))

        local total=math.max(1,CFG.OVERDRIVE_TEMPO*CFG.FPS)
        local largura=math.floor(155*overdrive/total)
        ui.rectfill(308,31,463,33,cor(CFG.FUNDO))
        if largura>0 then ui.rectfill(308,31,308+largura,33,cor(CFG.VERDE)) end
    else
        ui.print("SYSTEM INFECTED",318,17,cor(CFG.VERMELHO))
    end

    ui.print("DASH: BOTAO 5",10,252,cor(CFG.CINZA))
    ui.print("VIRUS: "..#virus_do_capeta,370,252,cor(CFG.VERMELHO_CLARO))
end

function desenhar_jogo()
    desenhar_rastro()
    desenhar_ponto()
    desenhar_virus()
    desenhar_jogador()
    desenhar_particulas()
    desenhar_hud()
end

function desenhar_intro()
    desenhar_fundo()
    ui.rectfill(24,32,456,230,cor(CFG.FUNDO_PAINEL))
    ui.rectfill(24,32,456,34,cor(CFG.VERMELHO))
    ui.print("BOOT SEQUENCE // ERROR",38,46,cor(CFG.VERMELHO))
    ui.print("--------------------------------",38,59,cor(CFG.VERMELHO_ESCURO))

    ui.print("> "..string.sub(CFG.INTRO_TEXTO,1,intro_indice),
        38,90,cor(CFG.BRANCO))

    if intro_indice>=#CFG.INTRO_TEXTO then
        ui.print("> "..string.sub(CFG.INTRO_TEXTO_2,1,intro_indice_2),
            38,112,cor(CFG.VERDE))
    end

    if frame_atual%30<15 then
        ui.rectfill(38+intro_indice*6,101,43+intro_indice*6,108,cor(CFG.VERMELHO))
    end

    ui.print("WARNING: UNAUTHORIZED PROCESS",38,166,cor(CFG.VERMELHO_CLARO))
    ui.print("MEMORY INTEGRITY: COMPROMISED",38,180,cor(CFG.VERMELHO))
    ui.print("PLEASE WAIT...",38,207,cor(CFG.CINZA))
end

function desenhar_menu()
    desenhar_fundo()
    ui.rectfill(35,27,445,243,cor(CFG.FUNDO_PAINEL))
    ui.rectfill(35,27,445,30,cor(CFG.VERMELHO))

    ui.print("SYSTEM",139+math.random(-1,1),50,cor(CFG.VERMELHO))
    ui.print("BREACH",139,73,cor(CFG.BRANCO))
    ui.print("// CRITICAL FAILURE //",139,94,cor(CFG.VERMELHO_CLARO))
    ui.rectfill(75,116,405,117,cor(CFG.VERMELHO_ESCURO))

    local pisca=frame_atual%40<28
    local fundo=pisca and CFG.VERMELHO or CFG.VERMELHO_ESCURO
    local texto=pisca and CFG.BRANCO or CFG.VERMELHO_CLARO

    ui.rectfill(145,133,335,164,cor(fundo))
    ui.print("[ PLAY ]",207,145,cor(texto))

    if CFG.MOSTRAR_CONTROLES then
        ui.print("MOVE: ARROWS",82,187,cor(CFG.CINZA))
        ui.print("DASH: BUTTON 5",260,187,cor(CFG.CINZA))
    end

    ui.print("SURVIVE THE INFECTION",142,216,cor(CFG.VERDE))
end

function desenhar_gameover()
    desenhar_fundo()
    ui.rectfill(45,27,435,243,cor(CFG.FUNDO_PAINEL))
    ui.rectfill(45,27,435,30,cor(CFG.VERMELHO))
    ui.print("CONNECTION LOST",130+math.random(-1,1),51,cor(CFG.VERMELHO))
    ui.print("SYSTEM FAILURE",147,72,cor(CFG.BRANCO))
    ui.rectfill(75,94,405,95,cor(CFG.VERMELHO_ESCURO))
    ui.print("FINAL SCORE",193,106,cor(CFG.CINZA))
    ui.print(tostring(score),224,127,cor(CFG.VERDE))
    ui.print("BEST COMBO: x"..melhor_combo,155,155,cor(CFG.VERMELHO_CLARO))
require "palette"
require "sprites"

-- =========================================================
-- CONFIGURACAO GERAL
-- Altere estes valores para personalizar o jogo.
-- =========================================================

CFG = {
    LARGURA = 480,
    ALTURA = 270,
    FPS = 60,

    -- CORES: formato hexadecimal RGB
    FUNDO = 0x080609,
    FUNDO_PAINEL = 0x180B10,
    VERMELHO = 0xFF243F,
    VERMELHO_ESCURO = 0x781426,
    VERMELHO_CLARO = 0xFF6174,
    VERDE = 0x45FF78,
    VERDE_ESCURO = 0x126B36,
    BRANCO = 0xF5F0F0,
    CINZA = 0x88777D,
    AMARELO = 0xFFE66D,

    -- JOGADOR
    PLAYER_RAIO = 5,
    PLAYER_ACELERACAO = 0.10,
    PLAYER_ATRITO = 0.10,
    PLAYER_VELOCIDADE_MAX = 5,
    PLAYER_DASH_VELOCIDADE = 12,
    PLAYER_DASH_COOLDOWN = 0, -- 0 = sem cooldown

    -- VIRUS
    VIRUS_INICIAIS = 1,
_sessao,145,174,cor(CFG.CINZA))

    if frame_atual%40<28 then
        ui.print("> PRESS BUTTON 5 TO REBOOT",100,207,cor(CFG.VERDE))
    end
end

function loop(frame)
    frame_atual=frame_atual+1
    atualizar_efeitos()

    if estado==0 then
        if frame_atual%math.max(1,CFG.INTRO_VELOCIDADE)==0 then
            if intro_indice<#CFG.INTRO_TEXTO then
                intro_indice=intro_indice+1
            elseif intro_indice_2<#CFG.INTRO_TEXTO_2 then
                intro_indice_2=intro_indice_2+1
            else
                intro_espera=intro_espera+1
                if intro_espera>=CFG.INTRO_ESPERA then estado=3 end
            end
        end

        if ui.btnp(4) then estado=3 end

    elseif estado==3 then
        menu_anim=menu_anim+1
        if ui.btnp(4) then iniciar_jogo() end

    elseif estado==1 then
        atualizar_jogo()

    elseif estado==2 then
        gameover_anim=gameover_anim+1
        if ui.btnp(4) then
            estado=3
            virus_do_capeta={}
            particulas={}
            rastro={}
            pl=gerar_jogador()
        end
    end

    for i=1,#Palette do ui.palset(i-1,Palette[i]) end
    ui.clip(0,0,CFG.LARGURA,CFG.ALTURA)

    local sx,sy=0,0
    if tremidinha>0 then
        local t=math.floor(tremidinha)
        if t>0 then sx=math.random(-t,t); sy=math.random(-t,t) end
    end

    ui.camera(0,0)
    desenhar_fundo()
    ui.camera(sx,sy)

    if estado==1 then
        desenhar_jogo()
    elseif estado==2 then
        desenhar_particulas()
    end

    ui.camera(0,0)

    if estado==0 then
        desenhar_intro()
    elseif estado==3 then
        desenhar_menu()
    elseif estado==2 then
        desenhar_gameover()
    end
end
