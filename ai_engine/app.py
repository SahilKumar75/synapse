# ai_engine/app.py

from flask import Flask, request, jsonify
import spacy
import re # Import regular expressions

app = Flask(__name__)

# Load the spaCy model we downloaded earlier
nlp = spacy.load("en_core_web_sm")

@app.route('/process', methods=['POST'])
def process_description():
    data = request.get_json()
    if not data or 'description' not in data:
        return jsonify({"error": "Description not provided"}), 400

    description = data['description']
    doc = nlp(description)

    # Simple extraction logic (can be improved later)
    quantity = None
    unit = None
    material = description

    # Use regex to find patterns like "500kg" or "2 tonnes"
    # This is often more reliable for specific patterns than general NER
    pattern = re.compile(r'(\d+\.?\d*)\s*(kg|ton|tonne|tonnes|liters|l)\b', re.IGNORECASE)
    match = pattern.search(description)

    if match:
        quantity = float(match.group(1))
        unit = match.group(2).lower()
        # Remove the found quantity/unit to better isolate the material name
        material = pattern.sub('', material).strip()

    structured_data = {
        "material": material,
        "quantity": quantity,
        "unit": unit
    }

    return jsonify(structured_data)

if __name__ == '__main__':
    # Run the AI server on a different port, e.g., 5002
    app.run(host='0.0.0.0', port=5002, debug=True)