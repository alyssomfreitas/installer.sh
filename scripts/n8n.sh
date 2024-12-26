#!/bin/bash
echo "Iniciando a instalação da Aplicação N8N..."
# Adicione aqui os comandos para instalar a Aplicação N8N.
# Instalador do N8N em Docker
# Autor: Alysson Freitas
# Versao: Atual

clear
echo "INICIANDO SETUP DO N8N..."
sleep 5
clear
host=$(sudo hostname -I | head -n1 | cut -d " " -f1)
sudo apt -y update
sudo apt -y upgrade
sudo apt -y autoremove
sudo timedatectl set-timezone America/Sao_Paulo
sudo apt install -y docker.io
docker run -d --restart unless-stopped --name n8n -e N8N_SECURE_COOKIE=false -e WEBHOOK_URL=http://$host:5678/ -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n
docker run --rm --user root -v ~/.n8n:/home/node/.n8n --entrypoint chown n8nio/n8n:latest -R node:node /home/node/.n8n
docker restart n8n
clear
echo "N8N INSTALADO COM SUCESSO!"
echo "Acesse a URL: http://${host}:5678"
echo ""
