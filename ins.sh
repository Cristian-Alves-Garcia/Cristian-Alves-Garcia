#!/bin/sh
# TinyCore DWM Auto-Installer
# Repo: https://github.com/seuusuario/tinycore-dwm-setup

set -e  # Para em caso de erro

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_BLUE="\033[34m"
COLOR_YELLOW="\033[33m"

print_status() {
    echo -e "${COLOR_BLUE}[*]${COLOR_RESET} $1"
}

print_success() {
    echo -e "${COLOR_GREEN}[+]${COLOR_RESET} $1"
}

print_warning() {
    echo -e "${COLOR_YELLOW}[!]${COLOR_RESET} $1"
}

# Verificar se é TinyCore
if [ ! -f /etc/sysconfig/tcuser ]; then
    echo "Este script é apenas para TinyCore Linux!"
    exit 1
fi

print_status "Iniciando instalação do ambiente DWM minimalista..."

# 1. Atualizar repositórios
print_status "Atualizando repositórios..."
tce-load -wi squashfs-tools > /dev/null 2>&1

# 2. Instalar pacotes
print_status "Instalando pacotes principais..."
CORE_APPS="dwm dmenu st nnn feh htop nano curl file tree unzip"
MEDIA_APPS="mpv moc"
NETWORK_APPS="wireless_tools wpa_suplicant"

for app in $CORE_APPS $MEDIA_APPS $NETWORK_APPS; do
    print_status "Instalando $app..."
    tce-load -wi "$app" > /dev/null 2>&1 || print_warning "Falha ao instalar $app"
done

# 3. Navegador (opcional - escolha um)
print_status "Instalando navegador leve..."
tce-load -wi netsurf > /dev/null 2>&1 || \
tce-load -wi links > /dev/null 2>&1 || \
print_warning "Navegador não instalado, use 'tce-load -wi firefox' depois"

# 4. Configurar ambiente
print_status "Configurando ambiente gráfico..."

# Xinitrc
cat > /home/tc/.xinitrc << 'EOF'
#!/bin/sh
# TinyCore DWM Environment

# Exportar variáveis
export PATH=$PATH:/usr/local/bin
export TERMINAL="st"
export BROWSER="netsurf"

# Wallpaper
if [ -f /opt/wallpaper.jpg ]; then
    feh --bg-fill /opt/wallpaper.jpg
else
    # Wallpaper padrão simples
    echo "Creating default wallpaper..."
    convert -size 1920x1080 gradient:#1a1a2e-#16213e /tmp/wall.png 2>/dev/null && \
    feh --bg-fill /tmp/wall.png || true
fi

# Status bar simples
{
    while true; do
        MEM=$(free -m | awk 'NR==2{printf "MEM: %sM", $3}')
        ROOT=$(df -h / | awk 'NR==2{printf "ROOT: %s", $5}')
        TIME=$(date '+%H:%M')
        BAT=""
        [ -f /sys/class/power_supply/BAT0/capacity ] && \
            BAT=" | BAT: $(cat /sys/class/power_supply/BAT0/capacity)%"
        xsetroot -name " $TIME | $MEM | $ROOT$BAT "
        sleep 5
    done
} &

# Iniciar autostart do DWM
[ -f ~/.dwm/autostart.sh ] && ~/.dwm/autostart.sh

# Executar DWM
exec dwm
EOF

chmod +x /home/tc/.xinitrc

# 5. Configurar autostart do DWM
mkdir -p /home/tc/.dwm
cat > /home/tc/.dwm/autostart.sh << 'EOF'
#!/bin/sh
# Script de autostart do DWM

# Network Manager (se instalado)
# if command -v nm-applet >/dev/null 2>&1; then
#     nm-applet &
# fi

# Clipboard manager
if command -v clipmenud >/dev/null 2>&1; then
    clipmenud &
fi

# Compositor para transparências (opcional)
# if command -v compton >/dev/null 2>&1; then
#     compton --config ~/.config/compton.conf &
# fi

# Terminal inicial (opcional)
# st &
EOF

chmod +x /home/tc/.dwm/autostart.sh

# 6. Configurar aliases úteis
cat > /home/tc/.ashrc << 'EOF'
# Aliases para TinyCore DWM
alias ls='ls --color=auto'
alias ll='ls -la'
alias update='tce-update'
alias install='tce-load -wi'
alias remove='tce-load -wu'
alias startx='~/.xinitrc'
alias wifi='sudo wifi.sh'
alias disks='sudo fdisk -l'
alias clean='sudo rm -rf /tmp/*'
alias reboot='sudo reboot'
alias poweroff='sudo poweroff'

# NNN com plugins
export NNN_PLUG='f:finder;o:fzopen;p:mocplay;d:diffs;t:nmount;v:imgview'
export NNN_FIFO='/tmp/nnn.fifo'
alias n='nnn -de'
EOF

# 7. Baixar wallpaper
print_status "Baixando wallpaper..."
curl -s -L -o /opt/wallpaper.jpg \
    https://raw.githubusercontent.com/linuxdroid/tinycore-wallpapers/main/minimal.jpg \
    || print_warning "Não foi possível baixar wallpaper"

# 8. Criar atalho de inicialização
cat > /home/tc/start-dwm << 'EOF'
#!/bin/sh
if [ -z "$DISPLAY" ]; then
    startx ~/.xinitrc
else
    echo "Já em modo gráfico!"
fi
EOF
chmod +x /home/tc/start-dwm

# 9. Salvar persistência
print_status "Salvando configurações..."
filetool.sh -b

print_success "Instalação concluída!"
echo ""
echo "==================== INSTRUÇÕES ===================="
echo "1. Reinicie o sistema"
echo "2. Para iniciar o DWM, execute:"
echo "   $ startx"
echo "   ou"
echo "   $ ./start-dwm"
echo ""
echo "3. Atalhos do DWM:"
echo "   Alt + Shift + Enter  = Novo terminal"
echo "   Alt + P              = Abrir dmenu"
echo "   Alt + 1-9            = Trocar workspace"
echo "   Alt + Shift + C      = Fechar janela"
echo "   Alt + F              = Tela cheia"
echo ""
echo "4. Comandos úteis:"
echo "   'n'                  = Abrir nnn (gerenciador arquivos)"
echo "   'install <pacote>'   = Instalar pacote"
echo "   'update'             = Atualizar pacotes"
echo "===================================================="
