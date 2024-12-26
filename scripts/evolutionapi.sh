#!/bin/bash
echo "Iniciando a instalação da Aplicação Evolution API..."
# Adicione aqui os comandos para instalar a Aplicação.
#!/bin/bash

# Evolution API Installation Script
# Author: Alysson Freitas
# Description: Instalação automática para Evolution API no Ubuntu Server

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to ask for confirmation
confirm() {
    while true; do
        read -p "$(echo -e ${YELLOW}$1 [y/N]:${NC} )" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* | "" ) return 1;;
            * ) echo "Por favor, responda com 'y' ou 'n'.";;
        esac
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "Por favor, execute como root"
fi

# Initial warning
log "Este script irá instalar a Evolution API em seu sistema."
log "Certifique-se de que está executando em uma máquina virtual Ubuntu Server no Proxmox."
if ! confirm "Deseja continuar com a instalação?"; then
    log "Instalação cancelada pelo usuário."
    exit 0
fi

# Function to check if a command was successful
check_success() {
    if [ $? -ne 0 ]; then
        error "$1"
    fi
}

# Update system
if confirm "Deseja atualizar os pacotes do sistema?"; then
    log "Atualizando pacotes do sistema..."
    apt-get update && apt-get upgrade -y
    check_success "Falha ao atualizar pacotes do sistema"
fi

# Set timezone
if confirm "Deseja configurar o timezone para America/Sao_Paulo?"; then
    log "Configurando timezone..."
    timedatectl set-timezone America/Sao_Paulo
    check_success "Falha ao configurar timezone"
    log "Timezone configurado para: $(timedatectl | grep "Time zone")"
fi

# Install required packages
if confirm "Deseja instalar os pacotes necessários (curl, git, build-essential)?"; then
    log "Instalando pacotes necessários..."
    apt-get install -y curl git build-essential
    check_success "Falha ao instalar pacotes necessários"
fi

# Install and configure PostgreSQL
if confirm "Deseja instalar e configurar o PostgreSQL?"; then
    log "Instalando PostgreSQL..."
    apt-get install -y postgresql postgresql-contrib
    check_success "Falha ao instalar PostgreSQL"

    log "Iniciando serviço PostgreSQL..."
    systemctl start postgresql
    systemctl enable postgresql
    check_success "Falha ao iniciar serviço PostgreSQL"

    log "Configurando PostgreSQL..."
    sudo -u postgres psql << EOF
CREATE USER evolution WITH PASSWORD '142536';
ALTER USER evolution WITH SUPERUSER;
ALTER USER evolution CREATEDB;
CREATE DATABASE evolution;
\q
EOF
    check_success "Falha ao configurar PostgreSQL"
fi

# Install Redis
if confirm "Deseja instalar e configurar o Redis?"; then
    log "Instalando Redis..."
    apt-get install -y redis-server
    check_success "Falha ao instalar Redis"

    log "Iniciando serviço Redis..."
    systemctl start redis-server
    systemctl enable redis-server
    check_success "Falha ao iniciar serviço Redis"

    redis-cli ping > /dev/null
    check_success "Redis não está respondendo"
fi

# Install NVM and Node.js
if confirm "Deseja instalar NVM e Node.js?"; then
    log "Instalando NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    check_success "Falha ao instalar NVM"

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    log "Instalando Node.js..."
    nvm install v20.10.0
    nvm use v20.10.0
    check_success "Falha ao instalar Node.js"
fi

# Clone Evolution API repository
if confirm "Deseja clonar o repositório da Evolution API?"; then
    log "Clonando repositório..."
    cd /opt
    git clone https://github.com/EvolutionAPI/evolution-api.git
    check_success "Falha ao clonar repositório"
fi

# Install project dependencies
if confirm "Deseja instalar as dependências do projeto?"; then
    log "Instalando dependências..."
    cd evolution-api
    npm install
    check_success "Falha ao instalar dependências"
fi

# Configure environment file
if confirm "Deseja configurar o arquivo de ambiente (.env)?"; then
    log "Configurando arquivo de ambiente..."
    cp .env.example .env
    check_success "Falha ao criar arquivo .env"

    cp .env .env.backup
    log "Backup do arquivo .env criado como .env.backup"

    log "Atualizando configurações do .env..."
    sed -i 's/DATABASE_CONNECTION_URI=.*/DATABASE_CONNECTION_URI='\''postgresql:\/\/evolution:142536@localhost:5432\/evolution?schema=public'\''/' .env
    sed -i 's/AUTHENTICATION_API_KEY=.*/AUTHENTICATION_API_KEY=429683C4C977415CAAFCCE10F7D57E11/' .env
    sed -i 's/CONFIG_SESSION_PHONE_CLIENT=.*/CONFIG_SESSION_PHONE_CLIENT=AprovTec/' .env
fi

# Generate and deploy database
if confirm "Deseja gerar e fazer deploy do banco de dados?"; then
    log "Gerando cliente Prisma..."
    npm run db:generate
    check_success "Falha ao gerar cliente Prisma"

    log "Fazendo deploy do banco de dados..."
    npm run db:deploy
    check_success "Falha ao fazer deploy do banco de dados"
fi

# Build application
if confirm "Deseja fazer build da aplicação?"; then
    log "Fazendo build..."
    npm run build
    check_success "Falha ao fazer build da aplicação"
fi

# Install and configure PM2
if confirm "Deseja instalar e configurar o PM2?"; then
    log "Instalando PM2..."
    npm install -g pm2
    check_success "Falha ao instalar PM2"

    log "Iniciando aplicação com PM2..."
    pm2 start 'npm run start:prod' --name ApiEvolution
    pm2 startup
    pm2 save --force
fi

# Final checks
if confirm "Deseja realizar verificações finais?"; then
    log "Realizando verificações finais..."

    if systemctl is-active --quiet postgresql; then
        log "PostgreSQL está rodando"
    else
        warning "PostgreSQL não está rodando"
    fi

    if systemctl is-active --quiet redis-server; then
        log "Redis está rodando"
    else
        warning "Redis não está rodando"
    fi

    if pm2 list | grep -q "ApiEvolution"; then
        log "Evolution API está rodando sob PM2"
    else
        warning "Evolution API não está rodando sob PM2"
    fi
fi

log "Instalação completada!"
log "Você pode acessar a API em http://SEU_IP_SERVIDOR:8080"
log "API Key: 429683C4C977415CAAFCCE10F7D57E11"
log "Lembre-se de proteger sua instalação e alterar a API key padrão"
