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
# Dynamically extract keyword classes from match_features.csv columns
keyword_classes = []
for col in feature_sample.columns:
    if col.startswith('offer_kw_'):
        keyword_classes.append(col.replace('offer_kw_', ''))
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
    location_dist = location_distance(offer['location'], request['location'])
    quantity_diff = abs(offer['quantity'] - request['quantity'])

    hazard_levels = {'Polyethylene': 1, 'Polypropylene': 1, 'PVC': 2, 'Acetone': 3, 'Ethanol': 2}
    offer_compound = offer.get('compound', '')
    request_compound = request.get('compound', '')
    offer_hazard_level = hazard_levels.get(offer_compound, 0)
    request_hazard_level = hazard_levels.get(request_compound, 0)

    def compound_class(compound):
        plastics = ['Polyethylene', 'Polypropylene', 'PVC']
        solvents = ['Acetone', 'Ethanol']
        if compound in plastics:
            return 'plastic'
        elif compound in solvents:
            return 'solvent'
        else:
            return 'other'
    offer_compound_class = compound_class(offer_compound)
    request_compound_class = compound_class(request_compound)
    chemical_compatible = int(offer_compound_class == request_compound_class)

    def can_transform(offer, request):
        if offer == 'Polyethylene' and request == 'Polypropylene':
            return 1
        return 0
    can_transform_val = can_transform(offer_compound, request_compound)

    region_laws = {
        'NY': ['Acetone'],
        'LA': [],
        'CHI': ['PVC'],
        'HOU': [],
        'PHI': ['Ethanol']
    }
    offer_loc = offer.get('location', '')
    request_loc = request.get('location', '')
    regulatory_allowed = 1
    if offer_compound in region_laws.get(offer_loc, []) or request_compound in region_laws.get(request_loc, []):
        regulatory_allowed = 0

    historical_match_freq = 0

    offer_date = offer.get('date', '')
    request_date = request.get('date', '')
    offer_month = 0
    request_month = 0
    recency_days = 0
    try:
        if offer_date and request_date:
            offer_month = pd.to_datetime(offer_date).month
            request_month = pd.to_datetime(request_date).month
            recency_days = abs((pd.to_datetime(request_date) - pd.to_datetime(offer_date)).days)
    except:
        pass

    offer_company_reputation = offer.get('reputation', 0)
    request_company_reputation = request.get('reputation', 0)

    # Build feature dict with all expected columns, including passthroughs
    features = {
        'offer_company': offer.get('company', ''),
        'offer_keywords': ','.join(offer_keywords),
        'offer_location': offer.get('location', ''),
        'offer_quantity': offer.get('quantity', 0),
        'offer_compound': offer_compound,
        'offer_date': offer_date,
        'offer_company_reputation': offer_company_reputation,
        'request_company': request.get('company', ''),
        'request_keywords': ','.join(request_keywords),
        'request_location': request.get('location', ''),
        'request_quantity': request.get('quantity', 0),
        'request_compound': request_compound,
        'request_date': request_date,
        'request_company_reputation': request_company_reputation,
        'location_distance': location_dist,
        'quantity_diff': quantity_diff,
        'keyword_overlap': overlap,
        'keyword_jaccard': jaccard,
        'offer_compound_class': offer_compound_class,
        'request_compound_class': request_compound_class,
        'chemical_compatible': chemical_compatible,
        'offer_hazard_level': offer_hazard_level,
        'request_hazard_level': request_hazard_level,
        'can_transform': can_transform_val,
        'regulatory_allowed': regulatory_allowed,
        'historical_match_freq': historical_match_freq,
        'offer_month': offer_month,
        'request_month': request_month,
        'recency_days': recency_days
    }
    # Add keyword one-hot features
    for i, kw in enumerate(keyword_classes):
        features[f'offer_kw_{kw}'] = offer_kw[i]
        features[f'request_kw_{kw}'] = request_kw[i]
    # Ensure all expected columns are present (fill missing with 0 or '')
    expected_cols = [col for col in feature_sample.columns if col != 'label']
    for col in expected_cols:
        if col not in features:
            features[col] = 0
    # Order features as expected
    ordered_features = {col: features[col] for col in expected_cols}
    return ordered_features

@app.route('/match_score', methods=['POST'])
def match_score():
    data = request.get_json()
    if not data or 'offer' not in data or 'request' not in data:
        return jsonify({'error': 'Missing offer or request data'}), 400
    offer = data['offer']
    request_data = data['request']
    try:
        features = extract_features(offer, request_data)
        X = pd.DataFrame([features])
        score = model.predict_proba(X)[0][1]  # Probability of good match
        return jsonify({'match_score': float(score)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/matches', methods=['GET'])
def get_rule_based_matches():
    try:
        df = pd.read_csv('rule_based_matches.csv')
        matches = df.to_dict(orient='records')
        return jsonify(matches)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=True)
