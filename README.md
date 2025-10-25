# Party

A party game platform where you can play party-style games with your friends
right from your phone. No signup required - just start a game and share the
link.

## Games

**Loaded Questions** - A hilarious guessing game where players answer creative
prompts, then try to match who said what. Perfect for getting to know your
friends better (or discovering how weird they really are).

**Burn Unit** *(Coming Soon)* - A competitive roasting game where players
submit their best burns and vote on the most savage ones. Think you're witty?
Prove it.

## Requirements

- Ruby 3.3+
- Node.js 18+
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
