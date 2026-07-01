# Home Server

Projeto do meu servidor local com stack Docker preparado para versionamento e restauração rápida.

## Objetivo

Depois de formatar o servidor, o fluxo ideal fica:

1. Clonar o repositório.
2. Ajustar o arquivo `.env` se necessário.
3. Rodar um único comando para subir tudo.

## Subir o stack

```bash
./scripts/bootstrap.sh
```

O script:

- cria o `.env` a partir do `.env.example` caso ele ainda não exista;
- ajusta `PUID` e `PGID` automaticamente para o usuário atual;
- cria os diretórios persistentes esperados pelo compose;
- valida a configuração do `docker compose`;
- sobe os containers em background.

## Serviços

O n8n fica disponível em:

```text
http://localhost:9010/
```

Se você acessar o n8n por outro host da rede, ajuste `N8N_HOST` e `N8N_WEBHOOK_URL` no `.env` para o IP ou domínio usado no navegador. Em HTTP local/LAN, `N8N_SECURE_COOKIE=false` evita o bloqueio de cookie seguro; para exposição pública, prefira HTTPS e cookie seguro.

O Swing Music fica disponível em:

```text
http://localhost:9012/
```

Na rede local ou pela VPN Tailscale, acesse pelo nome estável do servidor:

```text
http://e-cube:9012/
```

## Provisionar um host novo

Em um Ubuntu ou Debian recém-instalado, o fluxo pode ser automatizado com:

```bash
./scripts/provision-ubuntu.sh
```

Esse script:

- instala `git`, `curl` e Docker se estiverem ausentes;
- clona ou atualiza o repositório em `/opt/media-stack`;
- executa o bootstrap do stack.

Depois que o repositório estiver publicado no GitHub, isso também permite um fluxo de um comando via `curl`, se você quiser adotar esse modelo.

## Estrutura versionada

O repositório versiona:

- infraestrutura do stack (`docker-compose.yml`);
- variáveis de exemplo (`.env.example`);
- scripts de bootstrap e backup;
- documentação do ambiente.

O repositório **não** versiona:

- bancos SQLite;
- caches;
- chaves geradas automaticamente;
- configs sensíveis e estado de aplicações.

## Backup do estado

Para restaurar o ambiente completo com configurações dos aplicativos, gere um backup antes de formatar:

```bash
./scripts/backup-state.sh
```

Isso cria um arquivo compactado em `./backups/`.

Depois da reinstalação, com o repositório já clonado, restaure com:

```bash
./scripts/restore-state.sh /caminho/do/arquivo.tar.gz
```

Em seguida, rode:

```bash
./scripts/bootstrap.sh
```

## Fluxo recomendado após reinstalar o Linux

```bash
git clone git@github.com:altairbarbosa/home-server.git
cd home-server
./scripts/bootstrap.sh
```

Se preferir um fluxo realmente de um único comando após o clone, o próprio `bootstrap.sh` já cria o `.env` automaticamente quando ele estiver ausente.
