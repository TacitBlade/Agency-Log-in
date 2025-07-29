# Agency Login App

A secure login system built with Flask for agency management.

## Features

- User authentication system
- Session management
- Responsive web interface
- Health check endpoint
- AWS EC2 deployment ready

## Local Development

### Prerequisites

- Python 3.7+
- pip

### Setup

1. Clone the repository:
```bash
git clone https://github.com/TacitBlade/Agency-Log-in.git
cd Agency-Log-in
```

2. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run the application:
```bash
python app.py
```

5. Open your browser and go to `http://localhost:5000`

## Default Credentials

- **Admin**: username: `admin`, password: `password123`
- **User**: username: `user`, password: `userpass`

## AWS Deployment

For detailed AWS deployment instructions, see [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)

### Quick Deploy

1. Update the configuration in `deploy.ps1` (Windows) or `deploy.sh` (Linux/Mac)
2. Run the deployment script:
   - Windows: `.\deploy.ps1`
   - Linux/Mac: `./deploy.sh`

## API Endpoints

- `GET /` - Home page (redirects to login if not authenticated)
- `GET /login` - Login page
- `POST /login` - Process login
- `GET /dashboard` - User dashboard (requires authentication)
- `GET /logout` - Logout user
- `GET /health` - Health check endpoint

## Environment Variables

Create a `.env` file based on `.env.example`:

- `FLASK_ENV`: Environment (development/production)
- `FLASK_DEBUG`: Debug mode (true/false)
- `SECRET_KEY`: Flask secret key for sessions
- `HOST`: Host to bind the application
- `PORT`: Port to run the application

## Security Notes

- Change default passwords in production
- Use strong secret keys
- Enable HTTPS in production
- Configure proper firewall rules
- Regular security updates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.
