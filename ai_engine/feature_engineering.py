import pandas as pd
from sklearn.preprocessing import MultiLabelBinarizer
from geopy.distance import geodesic
from db_setup import db_companies, db_waste_streams, db_input_needs

# Location coordinates for distance calculation
location_coords = {
    'NY': (40.7128, -74.0060),
    'LA': (34.0522, -118.2437),
    'CHI': (41.8781, -87.6298),
    'HOU': (29.7604, -95.3698),
    'PHI': (39.9526, -75.1652)
}

def location_distance(loc1, loc2):
    return geodesic(location_coords[loc1], location_coords[loc2]).km

def process_keywords(df):
    mlb = MultiLabelBinarizer()
    offer_keywords = df['offer_keywords'].apply(lambda x: x.split(','))
    request_keywords = df['request_keywords'].apply(lambda x: x.split(','))
    offer_kw = mlb.fit_transform(offer_keywords)
    request_kw = mlb.transform(request_keywords)
    # Overlap count
    overlap = [len(set(o).intersection(set(r))) for o, r in zip(offer_keywords, request_keywords)]
    # Jaccard similarity
    jaccard = [len(set(o).intersection(set(r))) / len(set(o).union(set(r))) for o, r in zip(offer_keywords, request_keywords)]
    return offer_kw, request_kw, overlap, jaccard, mlb.classes_

def engineer_features(df):
    offer_kw, request_kw, overlap, jaccard, classes = process_keywords(df)
    df['location_distance'] = df.apply(lambda row: location_distance(row['offer_location'], row['request_location']), axis=1)
    df['quantity_diff'] = abs(df['offer_quantity'] - df['request_quantity'])
    df['keyword_overlap'] = overlap
    df['keyword_jaccard'] = jaccard
    # Add keyword one-hot features
    for i, kw in enumerate(classes):
        df[f'offer_kw_{kw}'] = offer_kw[:, i]
        df[f'request_kw_{kw}'] = request_kw[:, i]

    # --- Advanced Features ---
    # Chemical compatibility (dummy logic: same compound class)
    def compound_class(compound):
        plastics = ['Polyethylene', 'Polypropylene', 'PVC']
        solvents = ['Acetone', 'Ethanol']
        if compound in plastics:
            return 'plastic'
        elif compound in solvents:
            return 'solvent'
        else:
            return 'other'

    df['offer_compound_class'] = df['offer_compound'].apply(compound_class)
    df['request_compound_class'] = df['request_compound'].apply(compound_class)
    df['chemical_compatible'] = (df['offer_compound_class'] == df['request_compound_class']).astype(int)

    # Hazard level feature
    hazard_levels = {'Polyethylene': 1, 'Polypropylene': 1, 'PVC': 2, 'Acetone': 3, 'Ethanol': 2}
    df['offer_hazard_level'] = df['offer_compound'].map(hazard_levels).fillna(0)
    df['request_hazard_level'] = df['request_compound'].map(hazard_levels).fillna(0)

    # Transformation process (dummy: can offer compound be converted to request compound)
    def can_transform(offer, request):
        if offer == 'Polyethylene' and request == 'Polypropylene':
            return 1
        return 0
    df['can_transform'] = df.apply(lambda row: can_transform(row['offer_compound'], row['request_compound']), axis=1)

    # Regulatory constraints (region-specific, dummy logic)
    region_laws = {
        'NY': ['Acetone'],
        'LA': [],
        'CHI': ['PVC'],
        'HOU': [],
        'PHI': ['Ethanol']
    }
    def is_regulatory_allowed(row):
        offer = row['offer_compound']
        request = row['request_compound']
        offer_loc = row['offer_location']
        request_loc = row['request_location']
        if offer in region_laws.get(offer_loc, []) or request in region_laws.get(request_loc, []):
            return 0
        return 1
    df['regulatory_allowed'] = df.apply(is_regulatory_allowed, axis=1)

    # Historical match frequency (dummy: count previous matches between companies)
    # In real use, this should query a match history database
    df['historical_match_freq'] = 0  # Placeholder, to be filled with real data

    # Time-based features (seasonality, recency)
    if 'offer_date' in df.columns and 'request_date' in df.columns:
        df['offer_month'] = pd.to_datetime(df['offer_date']).dt.month
        df['request_month'] = pd.to_datetime(df['request_date']).dt.month
        df['recency_days'] = (pd.to_datetime(df['request_date']) - pd.to_datetime(df['offer_date'])).dt.days.abs()
    else:
        df['offer_month'] = 0
        df['request_month'] = 0
        df['recency_days'] = 0

    # Company reputation/feedback score (dummy: random or from company profile)
    if 'offer_company_reputation' in df.columns:
        df['offer_company_reputation'] = df['offer_company_reputation']
    else:
        df['offer_company_reputation'] = 0
    if 'request_company_reputation' in df.columns:
        df['request_company_reputation'] = df['request_company_reputation']
    else:
        df['request_company_reputation'] = 0

    return df


# Example: Fetch data from MongoDB and prepare for feature engineering
def fetch_match_data():
    # Get all companies
    companies = list(db_companies.find())
    # Get all waste streams
    wastes = list(db_waste_streams.find())
    # Get all input needs
    needs = list(db_input_needs.find())
    # Example: Pairwise matching (can be improved)
    match_rows = []
    for waste in wastes:
        for need in needs:
            offer_company = next((c for c in companies if c['_id'] == waste['company_id']), None)
            request_company = next((c for c in companies if c['_id'] == need['company_id']), None)
            if offer_company and request_company:
                match_rows.append({
                    'offer_company': offer_company['name'],
                    'offer_location': offer_company.get('location', ''),
                    'offer_compound': waste['compound'],
                    'offer_quantity': waste['quantity'],
                    'offer_keywords': ','.join(waste.get('properties', {}).get('keywords', [])),
                    'request_company': request_company['name'],
                    'request_location': request_company.get('location', ''),
                    'request_compound': need['compound'],
                    'request_quantity': need['quantity'],
                    'request_keywords': ','.join(need.get('properties', {}).get('keywords', [])),
                })
    return pd.DataFrame(match_rows)

if __name__ == "__main__":
    df = fetch_match_data()
    if not df.empty:
        df = engineer_features(df)
        # Save engineered features for model training
        df.to_csv('match_features.csv', index=False)
        print('Feature engineering complete: match_features.csv')
    else:
        print('No match data found in MongoDB.')
