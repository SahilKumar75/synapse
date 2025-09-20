import pandas as pd
from sklearn.preprocessing import MultiLabelBinarizer
from geopy.distance import geodesic

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
    return df

df = pd.read_csv('match_dataset.csv')
df = engineer_features(df)
# Save engineered features for model training
df.to_csv('match_features.csv', index=False)
print('Feature engineering complete: match_features.csv')
