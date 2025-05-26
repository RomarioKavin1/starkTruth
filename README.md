# starkTruth - World's First Steganography Powered Social Media on Starknet

A Flutter-based social media application that uses steganography to provide AI-proof content, built on the Starknet blockchain.

## Contract Deployment

**Sepolia Testnet**: [0x01cac254acbcd5c2a68c3a5aa04b58466d6cb0e578a431c0f4a68c2790dff610](https://sepolia.starkscan.co/contract/0x01cac254acbcd5c2a68c3a5aa04b58466d6cb0e578a431c0f4a68c2790dff610)

## Prerequisites

- Flutter SDK (v3.0 or higher)
- Dart SDK (v2.17 or higher)
- Python 3.8 or higher
- pip (Python package manager)
- Android Studio / Xcode (for mobile development)
- Git

## Project Structure

```
starkTruth/
├── lib/                    # Flutter application source code
├── contracts/              # Cairo smart contracts
│   ├── src/               # Contract source files
│   ├── tests/             # Contract tests
│   └── README.md          # Contract documentation
├── steganography/          # Python backend for steganography operations
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
└── web/                   # Web-specific files
```

## Features

- **Steganography Integration**: Hide messages within images using advanced steganographic techniques
- **Starknet Blockchain**: Decentralized storage and verification using Cairo smart contracts
- **AI-Proof Content**: Content verification through blockchain and steganography
- **Cross-Platform**: Available on Android, iOS, and Web
- **Secret Management**: Create and verify secrets with post associations

## Setup and Running Instructions

### 1. Backend Setup (Steganography Server)

Navigate to the steganography directory:

```bash
cd steganography
```

Create a Python virtual environment:

```bash
# On macOS/Linux
python3 -m venv venv

# On Windows
python -m venv venv
```

Activate the virtual environment:

```bash
# On macOS/Linux
source venv/bin/activate

# On Windows
.\venv\Scripts\activate
```

Install Python dependencies:

```bash
pip install -r requirements.txt
```

Start the steganography server:

```bash
python server.py
```

Copy the server URL from the console (typically `http://localhost:5000`)

### 2. Flutter App Setup

Navigate to the project root directory:

```bash
cd starkTruth
```

Install Flutter dependencies:

```bash
flutter pub get
```

Create a copy of the `.env.example` file and name it `.env`, then update it with required details including the steganography server URL:

```bash
cp .env.example .env
```

Update the `.env` file with:

- Steganography server URL
- Starknet RPC endpoints
- Any other required API keys

### 3. Running the Application

For development on different platforms:

**Android:**

```bash
flutter run -d android
```

**iOS:**

```bash
flutter run -d ios
```

**Web:**

```bash
flutter run -d web-server --web-port 3000
```

The web application will be available at `http://localhost:3000`

## Smart Contract Integration

The application uses the SecretManager contract deployed on Starknet Sepolia testnet. The contract provides:

- **Secret Creation**: Generate pseudo-random secret IDs
- **Post Association**: Link secrets with post metadata
- **Verification**: Verify and retrieve secret information

### Contract Functions

- `create_pre_secret(user)` - Creates a new secret
- `associate_post_details(secret_id, post_id, duration)` - Associates post details
- `verify_secret(secret_id)` - Verifies and retrieves secret data

## Development

## Technology Stack

- **Frontend**: Flutter/Dart
- **Blockchain**: Starknet (Cairo 2)
- **Backend**: Python (Steganography)
- **SDK**: Starknet Dart SDK
- **Testing**: Starknet Foundry, Flutter Test Framework, Starkli

## Troubleshooting

If you encounter any issues:

1. Ensure the steganography server is running on the correct port
2. Check that the `.env` file has the correct API URLs and configuration
3. Verify that all dependencies are installed correctly:
   ```bash
   flutter doctor
   ```
4. Check Flutter console for any frontend errors
5. Check the terminal running the steganography server for backend errors
6. Ensure you have the latest Flutter SDK version
7. For Starknet connectivity issues, verify RPC endpoints in `.env`

## Support

For any issues or questions:

- **Telegram**: [@romariokavin](https://t.me/romariokavin)
- **Email**: romario7kavin@gmail.com
- **Issues**: Open an issue in this repository

## Acknowledgments

- Starknet team for the robust blockchain infrastructure
- Flutter team for the excellent cross-platform framework
- Open source steganography libraries and research
