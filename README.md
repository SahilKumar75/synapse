# Synapse

Synapse is a full-stack platform for matching industrial material offers and requests using AI-powered feature engineering and machine learning. It consists of three main components: AI Engine (Python), Backend API (Node.js/Express), and a Flutter Frontend.

## Project Structure

- **ai_engine/** (Python, Flask)
  - `app.py`: NLP service for extracting structured data from material descriptions.
  - `feature_engineering.py`: Processes raw match data, engineers features for ML.
  - `generate_match_dataset.py`: Generates synthetic offer/request match data.
  - `train_match_model.py`: Trains a Random Forest model to predict match quality.
  - `match_endpoint.py`: API for scoring matches using the trained model.
  - Data files: `match_dataset.csv`, `match_features.csv`, `match_model.pkl`.

- **backend/** (Node.js, Express, MongoDB)
  - `server.js`: Main API server, connects to MongoDB, exposes REST endpoints.
  - `middleware/auth.js`: JWT authentication middleware.
  - `models/`: Mongoose schemas for User, Listing, Notification.
  - `routes/`: API routes for users, listings, notifications, places (Google Maps).
  - `package.json`: Backend dependencies.

- **frontend/synapse_app/** (Flutter)
  - `lib/main.dart`: App entry point.
  - `pubspec.yaml`: Flutter dependencies and asset configuration.
  - Assets: Logo, fonts, images.
  - Platform folders: Android, iOS, web, etc.

## Key Features

- **AI Engine**: Extracts material, quantity, and unit from descriptions; engineers features; trains and serves a match prediction model.
- **Backend API**: User authentication, CRUD for listings, notifications, geolocation, and matching logic.
- **Frontend App**: User interface for posting offers/requests, viewing matches, and notifications.

## Setup & Usage

1. **AI Engine**: Install Python dependencies (`spacy`, `scikit-learn`, `geopy`, `flask`, etc.), run Flask services on ports 5002 (NLP) and 5003 (match scoring).
2. **Backend**: Install Node.js dependencies, configure `.env` with `MONGO_URI`, `JWT_SECRET`, and API keys, then start the server.
3. **Frontend**: Install Flutter dependencies, run the app on your target platform.

## Data Flow

- Users post offers/requests via the frontend.
- Backend processes listings, calls AI Engine for NLP and match scoring.
- Listings and notifications are stored in MongoDB.
- Matching logic uses both rule-based and ML-based approaches.

## License

This project is licensed under the ISC License.

## How to Run

### 1. AI Engine (Python)
1. Navigate to the `ai_engine/` directory.
2. Install dependencies:
  ```bash
  pip install -r requirements.txt
  ```
  (If no `requirements.txt`, install: flask, spacy, scikit-learn, geopy, pandas, joblib)
3. Download spaCy model:
  ```bash
  python -m spacy download en_core_web_sm
  ```
4. Generate synthetic data and features:
  ```bash
  python generate_match_dataset.py
  python feature_engineering.py
  ```
5. Train the model:
  ```bash
  python train_match_model.py
  ```
6. Start NLP and match endpoints:
  ```bash
  python app.py      # Runs on port 5002
  python match_endpoint.py  # Runs on port 5003
  ```

### 2. Backend (Node.js)
1. Navigate to the `backend/` directory.
2. Install dependencies:
  ```bash
  npm install
  ```
3. Create a `.env` file with:
  ```env
  MONGO_URI=your_mongodb_uri
  JWT_SECRET=your_jwt_secret
  OPENCAGE_API_KEY=your_opencage_key
  GOOGLE_API_KEY=your_google_api_key
  ```
4. Start the server:
  ```bash
  node server.js
  ```

### 3. Frontend (Flutter)
1. Navigate to `frontend/synapse_app/`.
2. Install dependencies:
  ```bash
  flutter pub get
  ```
3. Run the app:
  ```bash
  flutter run
  ```
  (Choose your target device: Android, iOS, Web, etc.)
