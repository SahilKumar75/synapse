import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score
import joblib

def main():
    # Load engineered features
    df = pd.read_csv('../match_features.csv')
    print('Columns before strip:', list(df.columns))
    # Handle possible whitespace or encoding issues
    df.columns = df.columns.str.strip()
    print('Columns after strip:', list(df.columns))
    # Load engineered features
    df = pd.read_csv('../match_features.csv')

    # Drop non-numeric/non-feature columns, but keep label
    drop_cols = ['offer_company', 'request_company', 'offer_location', 'request_location', 'offer_keywords', 'request_keywords', 'offer_compound_class', 'request_compound_class']
    feature_cols = [col for col in df.columns if col not in drop_cols and col != 'label']
    X = df[feature_cols]
    # Try to access label column robustly
    label_col = None
    for col in df.columns:
        if col.lower() == 'label':
            label_col = col
            break
    if label_col:
        y = df[label_col]
    else:
        raise ValueError("'label' column not found after cleaning column names. Columns: {}".format(list(df.columns)))

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train model
    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    # Evaluate
    y_pred = clf.predict(X_test)
    print('Accuracy:', accuracy_score(y_test, y_pred))
    print(classification_report(y_test, y_pred))

    # Save model
    joblib.dump(clf, '../match_model.pkl')
    print('Model saved to match_model.pkl')

if __name__ == '__main__':
    main()
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
