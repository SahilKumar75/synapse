import pandas as pd
import numpy as np

# Synthetic data generation for Offers and Requests
np.random.seed(42)
materials = ['steel', 'plastic', 'wood', 'glass', 'copper', 'aluminum']
locations = ['NY', 'LA', 'CHI', 'HOU', 'PHI']

def random_keywords():
    return list(np.random.choice(materials, size=np.random.randint(1, 4), replace=False))

def random_location():
    return np.random.choice(locations)

def random_quantity():
    return np.random.randint(1, 100)

def match_label(offer, request):
    # Simple rule: overlap in keywords and same location = good match
    if set(offer['keywords']).intersection(set(request['keywords'])) and offer['location'] == request['location']:
        return 1
    return 0

data = []
for _ in range(500):
    offer = {
        'offer_keywords': random_keywords(),
        'offer_location': random_location(),
        'offer_quantity': random_quantity()
    }
    request = {
        'request_keywords': random_keywords(),
        'request_location': random_location(),
        'request_quantity': random_quantity()
    }
    label = match_label({'keywords': offer['offer_keywords'], 'location': offer['offer_location']},
                        {'keywords': request['request_keywords'], 'location': request['request_location']})
    data.append({
        'offer_keywords': ','.join(offer['offer_keywords']),
        'offer_location': offer['offer_location'],
        'offer_quantity': offer['offer_quantity'],
        'request_keywords': ','.join(request['request_keywords']),
        'request_location': request['request_location'],
        'request_quantity': request['request_quantity'],
        'label': label
    })

df = pd.DataFrame(data)
df.to_csv('match_dataset.csv', index=False)
print('Synthetic dataset created: match_dataset.csv')
