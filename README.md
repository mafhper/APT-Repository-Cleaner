# APT Repository Cleaner

Um script para detectar e remover automaticamente repositórios problemáticos no Ubuntu e distribuições baseadas em Debian.

## Funcionalidades

- Detecta automaticamente repositórios inacessíveis ou quebrados
- Remove arquivos de repositórios problemáticos em `/etc/apt/sources.list.d/`
- Limpa entradas problemáticas no arquivo `/etc/apt/sources.list`
- Remove arquivos de backup inválidos
- Executa limpeza avançada baseada em erros específicos do APT
- Funciona com repositórios PPA e fontes externas

## Requisitos

- Ubuntu, Debian ou qualquer distribuição baseada em Debian
- `curl` (geralmente já instalado)
- Permissões de administrador (sudo)

## Instalação

1. Clone este repositório:
   ```bash
   git clone https://github.com/seu-usuario/apt-repository-cleaner.git
   cd apt-repository-cleaner
   ```

2. Dê permissão de execução ao script:
   ```bash
   chmod +x corrigir_repositorios.sh
   ```

## Uso

Execute o script com permissões de administrador:

```bash
sudo ./corrigir_repositorios.sh
```

O script irá:
1. Verificar todos os repositórios configurados
2. Remover os repositórios problemáticos
3. Executar `apt update` para confirmar a correção
4. Realizar uma limpeza mais agressiva se necessário

## Exemplo de Saída

```
=== Iniciando verificação e limpeza de repositórios APT ===
Verificando repositórios em /etc/apt/sources.list.d/
Testando: https://ppa.launchpadcontent.net/me-davidsansome/clementine/ubuntu/
Repositório problemático encontrado: https://ppa.launchpadcontent.net/me-davidsansome/clementine/ubuntu/
Removendo arquivo: /etc/apt/sources.list.d/me-davidsansome-ubuntu-clementine-noble.sources
Verificando repositórios em /etc/apt/sources.list
Atualizando informações de repositórios...
✓ Todos os repositórios parecem estar funcionando corretamente
=== Limpeza de repositórios concluída ===
```

## Problemas Corrigidos

- Erro 404 em PPAs desatualizados
- Repositórios que não suportam versões recentes do Ubuntu
- Arquivos de backup com extensões inválidas
- Problemas com o Release file em repositórios

## Contribuição

Sinta-se à vontade para abrir issues ou enviar pull requests com melhorias.

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.
