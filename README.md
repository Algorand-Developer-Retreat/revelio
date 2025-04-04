# Revelio

Revelio is a platform for managing and documenting smart contracts on the Algorand blockchain. It provides a centralized registry for ARC56 contract specifications, making it easier for developers to discover, understand, and interact with smart contracts.

## Features

- **Contract Registry**: Store and manage ARC56 contract specifications
- **Project Management**: Organize contracts by project
- **Versioning**: Track contract upgrades and changes over time
- **API Access**: Programmatically access contract information
- **User Authentication**: Secure access to contract management

## Getting Started

### Prerequisites

- Ruby 3.2.0 or higher
- Rails 8.0.0 or higher
- PostgreSQL 12 or higher
- Node.js and Yarn for JavaScript dependencies

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/loedn/revelio.git
   cd revelio
   ```

2. Install dependencies:
   ```
   bundle install
   yarn install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Start the server:
   ```bash
   bin/rails s
   ```

5. Visit `http://localhost:3000` in your browser

## API Documentation

Revelio provides a RESTful API for accessing contract information:

### Endpoints

- `GET /api/v1/projects` - List all projects
- `GET /api/v1/contracts/:app_id` - Get contract by application ID
- `GET /api/v1/contracts/:app_id/by_round/:round_number` - Get contract by application ID and round number
- `GET /api/v1/contracts/project/:abbreviation` - Get all contracts for a project

For detailed API documentation, visit `/docs` in the application.

## Development

### Running Tests
```bash
bin/rails test
```
### Code Style

This project uses RuboCop for Ruby code style:
```bash
rubocop
```

### Linting
```bash
bin/rails lint
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- The Algorand Foundation for the ARC56 specification
- All contributors who have helped build and improve Revelio