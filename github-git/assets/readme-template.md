# Project Name

<!-- Short description — one or two sentences explaining what this project does. -->

## Features

- Feature 1
- Feature 2
- Feature 3

## Prerequisites

<!-- List required tools and minimum versions. -->

- [Node.js](https://nodejs.org/) >= 22
- [npm](https://www.npmjs.com/) >= 10

## Installation

```bash
git clone https://github.com/<owner>/<repo>.git
cd <repo>
npm install
```

## Usage

```bash
npm run dev
```

<!-- Add code examples or CLI usage if applicable. -->

## Configuration

<!-- Explain environment variables or config files. -->

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `DATABASE_URL` | Database connection string | — |

Copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
```

## Project Structure

```
src/
├── controllers/    # Request handlers
├── services/       # Business logic
├── models/         # Data models
├── routes/         # API routes
├── middleware/      # Express middleware
├── utils/          # Helper functions
└── index.ts        # Application entry point
```

## Running Tests

```bash
npm test
```

## Contributing

1. Create an issue describing the change
2. Create a branch from `develop` (`feature/<issue-number>-<slug>`)
3. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
4. Open a PR into `develop`
5. Wait for review and CI to pass

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

<!-- Choose one: MIT, Apache-2.0, GPL-3.0, or Proprietary -->

This project is licensed under the [MIT License](LICENSE).
