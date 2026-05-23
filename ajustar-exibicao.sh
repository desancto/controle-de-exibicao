#!/bin/bash

# Identifica a tela ativa conectada
TELA=$(xrandr | grep " connected" | cut -d' ' -f1 | head -n1)

# Identifica o ambiente de desktop para aplicar o comando correto de DPI
DESKTOP=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

# Resolução nativa
LARGURA_NAT=1920
ALTURA_NAT=1080

# Valores iniciais
margem_topo=0      # Quantos pixels pretos deixar no TOPO (encolhendo a imagem para baixo)
escala=1.00        # Fator de escala/zoom (1.00 = normal, 1.20 = maior/mais zoom)

aplicar_config() {
    # 1. Aplica a compressão vertical da tela via xrandr usando apenas a margem topo antiga
    if [ "$margem_topo" -eq 0 ]; then
        xrandr --output "$TELA" --transform none --scale 1x1 --panning 0x0
    else
        altura_disponivel=$(echo "$ALTURA_NAT - $margem_topo" | bc)
        fator_y=$(echo "scale=4; $ALTURA_NAT / $altura_disponivel" | bc)
        deslocamento_y=$(echo "scale=4; -($margem_topo * $fator_y)" | bc)
        
        xrandr --output "$TELA" \
               --fb "${LARGURA_NAT}x${ALTURA_NAT}" \
               --panning "${LARGURA_NAT}x${ALTURA_NAT}" \
               --transform "1,0,0,0,${fator_y},${deslocamento_y},0,0,1"
    fi

    # 2. ALTERAÇÃO SOLICITADA: Aplica a escala de ícones e textos via DPI (Sem mexer no xrandr)
    dpi=$(echo "scale=0; $escala * 96 / 1" | bc)
    
    # Contexto universal X11
    echo "Xft.dpi: $dpi" | xrdb -merge

    # Contexto GNOME / Ubuntu / Cinnamon
    if [[ "$DESKTOP" == *"gnome"* || "$DESKTOP" == *"ubuntu"* || "$DESKTOP" == *"cinnamon"* ]]; then
        gsettings set org.gnome.desktop.interface text-scaling-factor "$escala" 2>/dev/null
    fi

    # Contexto XFCE
    if [[ "$DESKTOP" == *"xfce"* ]]; then
        xfconf-query -c xsettings -p /Xft/DPI -s "$dpi" 2>/dev/null
    fi
}

restaurar_padrao() {
    margem_topo=0
    escala=1.00
    xrandr --output "$TELA" --transform none --scale 1x1 --panning 0x0
    aplicar_config
    clear
    echo "Configuração padrão de fábrica restaurada!"
    sleep 1.5
}

# Menu interativo
while true; do
    clear
    # Geração das barras visuais de progresso
    if [ "$margem_topo" -le 0 ]; then barra_margem=0; else
        barra_margem=$(echo "$margem_topo * 20 / 500" | bc 2>/dev/null)
        [ -z "$barra_margem" ] && barra_margem=0
        [ "$barra_margem" -gt 20 ] && barra_margem=20
    fi

    barra_escala=$(echo "($escala - 0.5) * 20 / 1.5" | bc 2>/dev/null | cut -d'.' -f1)
    [ -z "$barra_escala" ] && barra_escala=0
    [ "$barra_escala" -lt 0 ] && barra_escala=0
    [ "$barra_escala" -gt 20 ] && barra_escala=20

    echo "========================================================"
    echo "    PAINEL DE COMPRESSÃO VERTICAL & ESCALA PROPORCIONAL  "
    echo "========================================================"
    echo "  Dispositivo Ativo   : $TELA"
    echo "  Resolução Interna   : ${LARGURA_NAT}x$(echo "$ALTURA_NAT - $margem_topo" | bc) px"
    echo "--------------------------------------------------------"
    printf "  Margem Preta no TOPO: %-3d px  [" "$margem_topo"
    printf "%${barra_margem}s" | tr ' ' '#' 2>/dev/null
    printf "%$((20 - barra_margem))s" | tr ' ' '-'
    echo "]"
    
    printf "  Escala da Interface : %-4s     [" "$escala"
    printf "%${barra_escala}s" | tr ' ' '#' 2>/dev/null
    printf "%$((20 - barra_escala))s" | tr ' ' '-'
    echo "]"
    echo "--------------------------------------------------------"
    echo "  CONTROLES EM TEMPO REAL:"
    echo "     ▲  [Seta Cima]     Espremer imagem (Aumentar margem no topo)"
    echo "     ▼  [Seta Baixo]    Expandir imagem (Diminuir margem no topo)"
    echo "     ▶  [Seta Direita]  Aumentar Escala (Textos e ícones MAIORES)"
    echo "     ◀  [Seta Esquerda] Diminuir Escala (Textos e ícones MENORES)"
    echo " "
    echo "     [R] Resetar para o Padrão de Fábrica"
    echo "     [Espaço] Salvar e Confirmar  |  [Q] Sair"
    echo "========================================================"

    # Captura de teclas corrigida: lê 1 caractere instantaneamente
    read -rsn1 tecla
    
    # Se for uma sequência de escape (setas direcionais), captura o restante
    if [[ "$tecla" == $'\e' ]]; then
        read -rsn2 -t 0.1 resto
        tecla+="$resto"
    fi

    case "$tecla" in
        $'\e[A') # Seta para Cima
            margem_topo=$((margem_topo + 10))
            if [ $margem_topo -gt 600 ]; then margem_topo=600; fi
            aplicar_config
            ;;
        $'\e[B') # Seta para Baixo
            margem_topo=$((margem_topo - 10))
            if [ $margem_topo -lt 0 ]; then margem_topo=0; fi
            aplicar_config
            ;;
        $'\e[C') # Seta para Direita (Aumenta zoom da interface)
            escala=$(echo "$escala + 0.05" | bc)
            if (( $(echo "$escala > 2.00" | bc -l) )); then escala=2.00; fi
            aplicar_config
            ;;
        $'\e[D') # Seta para Esquerda (Diminui zoom da interface)
            escala=$(echo "$escala - 0.05" | bc)
            if (( $(echo "$escala < 0.50" | bc -l) )); then escala=0.50; fi
            aplicar_config
            ;;
        "r"|"R") # Tecla R
            restaurar_padrao
            ;;
        " ") # Barra de Espaço
            clear
            echo "========================================="
            echo "        CONFIRMAÇÃO DE SEGURANÇA          "
            echo "========================================="
            echo " A tela está legível? Você tem 5 segundos para confirmar."
            echo "   1) Sim, manter esta configuração"
            echo "   Qualquer outra tecla) Reverter imediatamente"
            echo "------------------------------------------"
            
            if read -t 5 -p " Opção: " conf && [ "$conf" = "1" ]; then
                clear
                echo "Configuração salva e fixada com sucesso!"
                exit 0
            else
                clear
                echo "Tempo expirado ou cancelado! Revertendo por segurança..."
                restaurar_padrao
            fi
            ;;
        "q"|"Q") # Tecla Q
            clear
            echo "Script encerrado."
            exit 0
            ;;
    esac
done
