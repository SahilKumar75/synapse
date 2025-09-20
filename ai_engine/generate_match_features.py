import pandas as pd
from feature_engineering import engineer_features

def main():
    # Load labeled match dataset
    df = pd.read_csv('../match_dataset.csv')

    # Add dummy columns for enhanced features if missing
    for col in ['offer_compound', 'request_compound', 'offer_date', 'request_date', 'offer_company_reputation', 'request_company_reputation']:
        if col not in df.columns:
            df[col] = '' if 'date' not in col and 'reputation' not in col else 0

    # Engineer features
    df_features = engineer_features(df)

    # Preserve label column if present
    if 'label' in df.columns:
        df_features['label'] = df['label']

    # Save engineered features
    df_features.to_csv('../match_features.csv', index=False)
    print('Engineered features saved to match_features.csv')

if __name__ == '__main__':
    main()