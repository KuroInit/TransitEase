# 🚗 Transitease - Car Park App

A project designed to provide real-time car park information and user preferences to enhance the parking experience. Built for seamless navigation and user convenience. 🚙

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white" alt="Google Cloud">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
</p>

## 🛠 Getting Started

Follow these instructions to set up the project and get it running on your local machine.

### Initial Setup

1. **Navigate to the project directory**

   ```bash
   cd <PROJECT-DIRECTORY>
   ```

2. **Clone the repository**

   ```bash
   git clone https://github.com/kuroinit/transitease.git
   ```

3. **Navigate to the cloned project directory**

   ```bash
   cd transitease
   ```

4. **Navigate to either the `client` or `transitease` folder as needed**
   ```bash
   cd <client|transitease>
   ```

### 🔧 Firebase Integration

#### Option 1: Using Firebase CLI (Preferred Method)

1. **Install Firebase CLI**

   MacOS/Linux:

   ```bash
   curl -sL https://firebase.tools | bash
   ```

   Test the installation:

   ```bash
   firebase login
   ```

   For additional information, visit the [Firebase CLI documentation](https://firebase.google.com/docs/cli/#install-cli-mac-linux).

#### Option 2: Using the Firebase Website

1. **Go to Firebase Console**

   - Visit Firebase Console and log in to your account

2. **Create or Select a Firebase Project**

   - Create a new project or select an existing one

3. **Add the iOS App**

   - Click Add App and choose iOS
   - Enter the iOS bundle ID found in `ios/Runner.xcodeproj/project.pbxproj`
   - Download the GoogleService-Info.plist file

4. **Place GoogleService-Info.plist in Your Flutter Project**
   - Move the `GoogleService-Info.plist` file to the `ios/Runner` directory

### 🐳 Backend Setup

#### Project Structure

```
.
├── crontab                   # Cron job configuration file
├── docker-compose.yml        # Docker Compose file for managing services
├── Dockerfile               # Docker configuration file for building the app image
├── initdb.py               # Script for initializing the database
├── logs/                   # Directory for storing log files
├── renew_token.py          # Python script for renewing tokens
├── requirements.txt        # Python dependencies
├── TransitEase.json       # JSON configuration file
└── update_vacancy.py      # Script for updating vacancy data
```

#### Environment Setup

Create a `.env` file in the `server` directory with the following parameters:

```env
URA_ACCESS_KEY=your_ura_access_key
URA_TOKEN=your_ura_token
FIREBASE_JSON=path/to/your/firebase.json
```

**Parameter Details:**

- `URA_ACCESS_KEY`: Access key from URA Carpark API
- `URA_TOKEN`: Authentication token (auto-refreshes every 24 hours)
- `FIREBASE_JSON`: Path to Firebase credentials file

#### Docker Setup

1. **Ensure Docker is installed**

   - Download from [Docker's official website](https://www.docker.com/products/docker-desktop) if needed

2. **Navigate to the backend directory**

   ```bash
   cd server
   ```

3. **Build the Docker image**

   ```bash
   docker compose build
   ```

4. **Run the Docker container**
   ```bash
   docker compose up
   ```

## 📝 Features

- Real-Time Car Park Availability: Track live parking space availability for cars and motorcycles through URA integration
- User Preferences: Save your preferred search radius and vehicle type settings
- Map Integration: Interactive map with real-time location tracking and car park locations
- Firestore Integration: Secure cloud storage for user preferences and car park data with offline access
- Location Services: Precise tracking and distance calculations using Geolocator
- Interactive UI: Clean, responsive Flutter interface with intuitive navigation
- Custom Notifications: Receive alerts for vacancy updates and system changes

## 🧠 Contributors - Team Transitease 🚗

- [Ashwin](https://github.com/KuroInit)
- [Jonathan](https://github.com/SZMJonathan)
- [Dave](https://github.com/DaveG0h)
- [Jun Heng](https://github.com/SpiderKing51094)

## 📖 References

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Programming Language](https://dart.dev/guides)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Google Cloud Services](https://cloud.google.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Cron Job Scheduling Guide](https://crontab.guru/)
- [URA Carpark API](https://www.ura.gov.sg/maps/api/)

## 📽 Demo Video

Watch the demo of the car park app in action: [Car Park App Demo](https://www.youtube.com/your-demo-link)

## 🔐 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
