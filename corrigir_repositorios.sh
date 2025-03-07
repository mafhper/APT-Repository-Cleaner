#!/bin/bash

echo "=== Iniciando verificação e limpeza de repositórios APT ==="

# Função para testar se um repositório está acessível
test_repository() {
    local repo_url="$1"
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url" 2>/dev/null)
    
    if [[ "$status_code" == "404" || "$status_code" == "000" ]]; then
        return 1  # Repositório inacessível
    else
        return 0  # Repositório OK
    fi
}

# Função para encontrar e remover repositórios com problemas
fix_repositories() {
    # Verificar arquivos .list e .sources em sources.list.d
    echo "Verificando repositórios em /etc/apt/sources.list.d/"
    
    for repo_file in $(find /etc/apt/sources.list.d/ -name "*.list" -o -name "*.sources" 2>/dev/null); do
        if [ -f "$repo_file" ]; then
            # Extrair URLs dos repositórios
            grep -o "http[s]*://[^\"' ]\+" "$repo_file" | while read -r repo_url; do
                echo "Testando: $repo_url"
                if ! test_repository "$repo_url"; then
                    echo "Repositório problemático encontrado: $repo_url"
                    echo "Removendo arquivo: $repo_file"
                    sudo rm -f "$repo_file"
                    # Também remover arquivos relacionados
                    sudo rm -f "${repo_file}.save" "${repo_file}.distUpgrade" 2>/dev/null
                    break
                fi
            done
        fi
    done
    
    # Verificar entradas no sources.list principal
    echo "Verificando repositórios em /etc/apt/sources.list"
    
    # Criar arquivo temporário
    temp_file=$(mktemp)
    
    # Processar linha por linha
    valid_lines=true
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*deb[[:space:]]+(http[s]*://[^[:space:]]+) ]]; then
            repo_url="${BASH_REMATCH[1]}"
            if ! test_repository "$repo_url"; then
                echo "Repositório problemático encontrado em sources.list: $repo_url"
                valid_lines=false
                continue
            fi
        fi
        echo "$line" >> "$temp_file"
    done < /etc/apt/sources.list
    
    # Substituir sources.list se necessário
    if [ "$valid_lines" = false ]; then
        sudo cp "$temp_file" /etc/apt/sources.list
        echo "Arquivo sources.list atualizado"
    fi
    
    # Limpar arquivo temporário
    rm -f "$temp_file"
}

# Função para limpar arquivos inválidos
clean_invalid_files() {
    echo "Removendo arquivos com extensões inválidas em /etc/apt/apt.conf.d/"
    sudo find /etc/apt/apt.conf.d/ -type f -name "*.bak*" -exec sudo rm -f {} \;
}

# Executar funções de limpeza
fix_repositories
clean_invalid_files

# Atualizar APT
echo "Atualizando informações de repositórios..."
sudo apt update

# Verificar se houve erros e executar remoção mais agressiva se necessário
if sudo apt update 2>&1 | grep -q "Err:"; then
    echo "Ainda existem erros. Executando remoção avançada..."
    
    # Capturar saída do apt update
    apt_output=$(sudo apt update 2>&1)
    
    # Extrair URLs com erro
    echo "$apt_output" | grep -A1 "Err:" | grep "http" | awk '{print $2}' | while read -r err_url; do
        # Extrair o domínio
        domain=$(echo "$err_url" | sed -E 's|https?://([^/]+)/.*|\1|')
        
        echo "Procurando arquivos com o domínio: $domain"
        
        # Usar add-apt-repository para remover PPAs problemáticos
        if [[ "$domain" == *"launchpadcontent.net"* ]]; then
            ppa_name=$(echo "$err_url" | grep -o "/~[^/]*/[^/]*/" | tr -d '/')
            if [ -n "$ppa_name" ]; then
                echo "Removendo PPA: $ppa_name"
                sudo add-apt-repository --remove "ppa:$ppa_name" -y
            fi
        fi
        
        # Remover manualmente arquivos contendo o domínio
        for sources_file in $(grep -l "$domain" /etc/apt/sources.list.d/* 2>/dev/null); do
            echo "Removendo arquivo: $sources_file"
            sudo rm -f "$sources_file"
        done
        
        # Remover do sources.list principal
        if grep -q "$domain" /etc/apt/sources.list; then
            echo "Removendo entradas do domínio $domain do sources.list"
            sudo sed -i "/$domain/d" /etc/apt/sources.list
        fi
    done
    
    echo "Atualizando após remoção avançada..."
    sudo apt update
else
    echo "✓ Todos os repositórios parecem estar funcionando corretamente"
fi

echo "=== Limpeza de repositórios concluída ==="
