#!/bin/bash
echo "Iniciando a instalação da Aplicação Update N8N..."
# Atualizador do N8N em Docker com Barra de Progresso e Instalação do Redis
# Autor: Alysson Freitas
# Versão: Atualizado

set -e  # Interrompe o script em caso de erro

clear
echo "INICIANDO ATUALIZAÇÃO DO N8N..."
sleep 2

# Função para barra de progresso
progress_bar() {
    local completed=$1
    local total=$2
    local width=50
    local progress=$((completed * width / total))
    local percent=$((completed * 100 / total))
    local bar=$(printf "%-${width}s" "#" | cut -c1-$((progress > 0 ? progress : 1)))

    echo -ne "\r[${bar// /-}] ${percent}%"
}

# Verificando o Docker
echo "Verificando o Docker..."
total_substeps=2
progress_bar 0 $total_substeps

(if ! command -v docker &> /dev/null; then
    echo -e "\nDocker não encontrado! Instale o Docker antes de prosseguir."
    exit 1
fi) && progress_bar 1 $total_substeps

(sudo systemctl start docker && sudo systemctl enable docker &> /dev/null) && progress_bar 2 $total_substeps

echo -e "\nDocker verificado com sucesso!"
sleep 1

# Instalar e configurar o Redis
echo "Instalando e configurando o Redis..."
total_substeps=5
progress_bar 0 $total_substeps

(sudo apt update &> /dev/null) && progress_bar 1 $total_substeps
(sudo apt install -y redis-server &> /dev/null) && progress_bar 2 $total_substeps

# Configurar o Redis para aceitar conexões externas (opcional)
(sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf &> /dev/null) && progress_bar 3 $total_substeps

# Definir uma senha para o Redis (opcional)
REDIS_PASSWORD="ou784339"  # Altere para a senha desejada
(sudo sed -i "s/# requirepass .*/requirepass $REDIS_PASSWORD/" /etc/redis/redis.conf &> /dev/null) && progress_bar 4 $total_substeps

# Reiniciar o Redis para aplicar as configurações
(sudo systemctl restart redis && sudo systemctl enable redis &> /dev/null) && progress_bar 5 $total_substeps

echo -e "\nRedis instalado e configurado com sucesso!"
sleep 1

# Parar e remover contêiner antigo
echo "Parando e removendo contêiner antigo..."
total_substeps=2
progress_bar 0 $total_substeps

(docker stop n8n &> /dev/null || true) && progress_bar 1 $total_substeps
(docker rm n8n &> /dev/null || true) && progress_bar 2 $total_substeps

echo -e "\nContêiner antigo removido com sucesso!"
sleep 1

# Atualizando a imagem do N8N
echo "Atualizando imagem do N8N..."
total_substeps=1
progress_bar 0 $total_substeps

(docker pull n8nio/n8n &> /dev/null) && progress_bar 1 $total_substeps

echo -e "\nImagem do N8N atualizada com sucesso!"
sleep 1

# Recriando e configurando o contêiner
echo "Recriando e configurando o contêiner do N8N..."
total_substeps=4
progress_bar 0 $total_substeps

host=$(hostname -I | awk '{print $1}')
(docker run -d --restart unless-stopped --name n8n \
    -e N8N_SECURE_COOKIE=false \
    -e WEBHOOK_URL=https://n8n.aprovtec.com.br \
    -e QUEUE_BULL_REDIS_HOST=127.0.0.1 \
    -e QUEUE_BULL_REDIS_PORT=6379 \
    -e QUEUE_BULL_REDIS_PASSWORD=$REDIS_PASSWORD \
    -p 5678:5678 \
    -v ~/.n8n:/home/node/.n8n \
    n8nio/n8n &> /dev/null) && progress_bar 1 $total_substeps

(docker run --rm --user root -v ~/.n8n:/home/node/.n8n --entrypoint chown \
    n8nio/base:16 -R node:node /home/node/.n8n &> /dev/null) && progress_bar 2 $total_substeps

(docker restart n8n &> /dev/null) && progress_bar 3 $total_substeps
progress_bar 4 $total_substeps

echo -e "\nN8N atualizado e configurado com sucesso!"
sleep 1

# Conclusão
echo "#############################################################"
echo "N8N ATUALIZADO COM SUCESSO!"
echo "Acesse a URL: http://${host}:5678"
echo "#############################################################"
