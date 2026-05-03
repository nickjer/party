# Party

A party game platform where you can play party-style games with your friends
right from your phone. No signup required - just start a game and share the
link.

Try it out at **[party.nicklas.cloud](https://party.nicklas.cloud/)**.

## Games

**Loaded Questions** - A hilarious guessing game where players answer creative
prompts, then try to match who said what. Perfect for getting to know your
friends better (or discovering how weird they really are).

**Burn Unit** - A "who's most likely to..." style game where players answer
prompts, then a rotating judge picks the winning answer. Think you know your
friends best? Prove it.

## Tech Stack

- **Rails 8** with [Hotwire](https://hotwired.dev/) (Turbo + Stimulus) for
  real-time multiplayer over WebSockets
- **Bootstrap 5** for styling
- **SQLite** with [Solid Queue / Cache / Cable](https://github.com/rails/solid_queue)
  — no Redis, no Postgres, no separate job server
- **RBS + Steep** for static type checking
- **Kamal** for deployment

## Requirements

- Ruby 4.0+
- Node.js 24+
- SQLite 3

## Setup

```bash
bin/setup
```

That's it! This will install dependencies, setup the database, and start the
development server at `http://localhost:3000`.

If you want to setup without starting the server:

```bash
bin/setup --skip-server
```

Then start manually with:

```bash
bin/dev
```

## Testing

```bash
# Run all tests
bin/rails test

# Type check with RBS (run before committing)
bin/steep check
```

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development patterns, architecture
documentation, and coding conventions.

## Deployment

```bash
bin/kamal deploy
```

Deployment configuration in `config/deploy.yml`.
