#!/bin/bash

# URL base do repositório
BASE_URL="https://raw.githubusercontent.com/alyssomfreitas/auto-installer/main/scripts"

# Função para exibir o menu
show_menu() {
    echo "Selecione a aplicação para instalar:"
    echo "1) Aplicação 1"
    echo "2) Aplicação 2"
    echo "3) Aplicação 3"
    echo "0) Sair"
}

# Lógica principal
while true; do
    show_menu
    read -p "Digite sua escolha: " CHOICE
    case $CHOICE in
        1)
            echo "Instalando Aplicação 1..."
            curl -s "${BASE_URL}/app1.sh" | bash
            ;;
        2)
            echo "Instalando Aplicação 2..."
            curl -s "${BASE_URL}/app2.sh" | bash
            ;;
        3)
            echo "Instalando Aplicação 3..."
            curl -s "${BASE_URL}/app3.sh" | bash
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida. Tente novamente."
            ;;
    esac
done