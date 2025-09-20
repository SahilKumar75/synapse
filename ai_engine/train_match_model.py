import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import joblib

# Load engineered features
df = pd.read_csv('match_features.csv')

# Features for model (exclude original columns and label)
feature_cols = [col for col in df.columns if col not in [
    'offer_keywords', 'offer_location', 'offer_quantity',
    'request_keywords', 'request_location', 'request_quantity', 'label']]
X = df[feature_cols]
y = df['label']

# Train/test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Evaluate
y_pred = model.predict(X_test)
print('Accuracy:', accuracy_score(y_test, y_pred))
print(classification_report(y_test, y_pred))

# Save model
joblib.dump(model, 'match_model.pkl')
print('Model training complete. Model saved as match_model.pkl')
