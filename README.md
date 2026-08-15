# Gitex

Projeto de exemplo em Elixir/Phoenix que implementa uma pipeline ETL para coletar dados do GitHub
e armazena repositórios em um banco PostgreSQL. Este repositório inclui também um dashboard em Phoenix
que mostra métricas da pipeline em tempo real e permite executar a pipeline a partir da interface.

Este projeto é preparado para uso em portfólio — engloba boas práticas de ETL, LiveView, Ecto e PubSub.

## Principais funcionalidades

- Pipeline ETL (discovery → extract → transform → load)
- Armazenamento em PostgreSQL (`repositories`)
- Monitor de métricas em tempo real (`Gitex.Pipeline.Monitor`) com PubSub
- Dashboard em Phoenix LiveView com métricas, filtros, gráficos simples e execução ao vivo

## Requisitos

- Elixir ~> 1.17
- Erlang/OTP compatível com Elixir
- PostgreSQL (local ou remoto)
- Node.js (opcional, para assets se necessário)

## Configuração rápida

1. Copie o arquivo de exemplo `.env.example` (ou crie `.env`) e configure a `DATABASE_URL` e outras variáveis:

```env
# .env
DATABASE_URL=ecto://USER:PASS@localhost:5432/gitex_dev
GITHUB_TOKEN=seu_token_aqui
```

2. Instale dependências (a partir do diretório do projeto):

```bash
mix deps.get
cd assets && npm ci # se você estiver usando assets locais
```

3. Crie o banco e rode migrações:

```bash
mix ecto.create
mix ecto.migrate
```

4. Rode a aplicação:

```bash
mix phx.server
# ou em desenvolvimento:
iex -S mix phx.server
```

5. Abra o dashboard no navegador:

```
http://localhost:4000/dashboard
```

## Executando a pipeline

- A maneira mais simples é usar o dashboard e inserir repositórios/usuários/organizações no formulário
  e clicar em `Executar pipeline`.
- Também é possível chamar `Gitex.Pipeline.run/1` diretamente no console IEx, por exemplo:

```elixir
# Em IEx (iex -S mix):
Gitex.Pipeline.run(%{repositories: ["elixir-lang/elixir"], users: [], organizations: []})
```

## Testes

Rode os testes via `mix test`. Dependendo do ambiente, você pode precisar preparar as dependências
ou bancos de teste.

```bash
mix test
```

## Observações

- O projeto utiliza `Dotenvy` para carregar variáveis de ambiente em `config/runtime.exs`.
- Se houver problemas na instalação de dependências no ambiente sandbox, libere a instalação
  (`mix deps.get`) localmente e depois rode `mix compile`.

## Contribuições

Este repositório é um exemplo para portfólio. Se quiser adaptar para uso pessoal, atualize
o arquivo `.env` com dados reais e remova quaisquer tokens sensíveis do histórico.

## Licença

Este projeto está disponível sob a licença especificada no arquivo `LICENSE`.# Gitex

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
