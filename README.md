# Tq2

Yet another web e-commerce app.

## Development

### Prerequisites

- Elixir (https://elixir-lang.org/)
- Yarn (https://yarnpkg.com/)
- PostgreSQL (https://www.postgresql.org/)
- Git (https://git-scm.com/)

### Dependencies

Install app dependencies:

```console
mix deps.install
```

Install assets dependencies:

```console
cd assets && yarn install && cd ..
```

Create database, run migrations and create initial account and user:

```console
mix ecto.setup
```

Run development web server:

```console
mix phx.server
```

### Git hooks

Install git pre commit hooks:

```console
cd .git/hooks/ && ln -s ../../scripts/git/hooks/pre-commit && cd ../../
```

### Utils

Generate new translations
```console
mix gettext.extract --merge
```
