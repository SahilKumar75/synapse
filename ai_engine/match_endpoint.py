from flask import Flask, request, jsonify
import joblib
import pandas as pd
from sklearn.preprocessing import MultiLabelBinarizer
from geopy.distance import geodesic
import os

app = Flask(__name__)

# Location coordinates for distance calculation
location_coords = {
    'NY': (40.7128, -74.0060),
    'LA': (34.0522, -118.2437),
    'CHI': (41.8781, -87.6298),
    'HOU': (29.7604, -95.3698),
    'PHI': (39.9526, -75.1652)
}

# Load trained model
model = joblib.load('match_model.pkl')

# Load keyword classes from feature engineering
feature_sample = pd.read_csv('match_features.csv', nrows=1)
keyword_classes = [col.replace('offer_kw_', '') for col in feature_sample.columns if col.startswith('offer_kw_')]
mlb = MultiLabelBinarizer(classes=keyword_classes)
mlb.fit([keyword_classes])

def location_distance(loc1, loc2):
    return geodesic(location_coords[loc1], location_coords[loc2]).km

def extract_features(offer, request):
    # Keyword features
    offer_keywords = offer.get('keywords', [])
    request_keywords = request.get('keywords', [])
    offer_kw = mlb.transform([offer_keywords])[0]
    request_kw = mlb.transform([request_keywords])[0]
    overlap = len(set(offer_keywords).intersection(set(request_keywords)))
    jaccard = len(set(offer_keywords).intersection(set(request_keywords))) / max(1, len(set(offer_keywords).union(set(request_keywords))))
    # Location and quantity features
    location_dist = location_distance(offer['location'], request['location'])
    quantity_diff = abs(offer['quantity'] - request['quantity'])
    # Build feature dict
    features = {
        'location_distance': location_dist,
        'quantity_diff': quantity_diff,
        'keyword_overlap': overlap,
        'keyword_jaccard': jaccard
    }
    # Add keyword one-hot features
    for i, kw in enumerate(keyword_classes):
        features[f'offer_kw_{kw}'] = offer_kw[i]
        features[f'request_kw_{kw}'] = request_kw[i]
    return features

@app.route('/match_score', methods=['POST'])
def match_score():
    data = request.get_json()
    if not data or 'offer' not in data or 'request' not in data:
        return jsonify({'error': 'Missing offer or request data'}), 400
    offer = data['offer']
    request = data['request']
    try:
        features = extract_features(offer, request)
        X = pd.DataFrame([features])
        score = model.predict_proba(X)[0][1]  # Probability of good match
        return jsonify({'match_score': float(score)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003, debug=True)
