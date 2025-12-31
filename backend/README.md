# YBEY Backend API

Python FastAPI backend for YBEY Flutter app.

## Setup Instructions

### 1. Install Python (if not already installed)
- Download from https://www.python.org/downloads/
- Make sure Python 3.8+ is installed

### 2. Create Virtual Environment (Recommended)
```bash
cd backend
python -m venv venv

# On Windows:
venv\Scripts\activate

# On Mac/Linux:
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Run the Server
```bash
python main.py
```

Or using uvicorn directly:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 5. Access API
- API will run on: `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs` (Swagger UI)
- Alternative docs: `http://localhost:8000/redoc`

## API Endpoints

### Register User
```
POST /api/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "password123",
  "confirm_password": "password123",
  "remember_me": true
}
```

### Get All Users
```
GET /api/users
```

### Get User by ID
```
GET /api/users/{user_id}
```

## Database

- Uses SQLite database (`ybey.db`) - created automatically
- Database file will be created in the `backend` folder
- Tables are created automatically on first run

## Flutter Integration

In your Flutter app, update the registration API call:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> submitRegistration() async {
  final url = Uri.parse('http://localhost:8000/api/register');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': _name,
      'email': _email,
      'password': _password,
      'confirm_password': _confirmPassword,
      'remember_me': _rememberMe,
    }),
  );
  
  if (response.statusCode == 200) {
    // Success
    print('Registration successful!');
  } else {
    // Error
    print('Error: ${response.body}');
  }
}
```

**Note:** For mobile/emulator, use `http://10.0.2.2:8000` (Android emulator) or your computer's IP address instead of `localhost`.

## Production Notes

- Change CORS origins to your actual domain
- Use PostgreSQL instead of SQLite for production
- Add proper authentication (JWT tokens)
- Use environment variables for sensitive data
- Add rate limiting
- Use HTTPS

