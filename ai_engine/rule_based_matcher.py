"""
Simple rule-based matcher for industrial symbiosis.
"""
import pandas as pd

# Parameters for matching
LOCATION_DISTANCE_THRESHOLD = 2000  # km (increased)
KEYWORD_OVERLAP_THRESHOLD = 0      # allow zero overlap
JACCARD_SIMILARITY_THRESHOLD = 0.0 # allow zero similarity

# Read engineered features
features_df = pd.read_csv('match_features.csv')

# Rule-based matching
matches = []
for idx, row in features_df.iterrows():
    compounds_match = row['offer_compound'] == row['request_compound']
    location_ok = row['location_distance'] <= LOCATION_DISTANCE_THRESHOLD
    overlap_ok = row['keyword_overlap'] >= KEYWORD_OVERLAP_THRESHOLD
    jaccard_ok = row['keyword_jaccard'] >= JACCARD_SIMILARITY_THRESHOLD
    if compounds_match and location_ok and (overlap_ok or jaccard_ok):
        matches.append({
            'offer_company': row['offer_company'],
            'request_company': row['request_company'],
            'compound': row['offer_compound'],
            'quantity_offer': row['offer_quantity'],
            'quantity_request': row['request_quantity'],
            'location_distance': row['location_distance'],
            'keyword_overlap': row['keyword_overlap'],
            'keyword_jaccard': row['keyword_jaccard']
        })

# Save matches to CSV
matches_df = pd.DataFrame(matches)
matches_df.to_csv('rule_based_matches.csv', index=False)
print(f'Rule-based matching complete: {len(matches)} matches found. Saved to rule_based_matches.csv')
