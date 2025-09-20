"""
Insert sample companies, waste streams, and input needs into MongoDB for testing feature engineering.
"""
from db_setup import insert_company, insert_waste_stream, insert_input_need

# Insert sample companies

# Clear existing collections for clean test data
from db_setup import db_companies, db_waste_streams, db_input_needs
db_companies.delete_many({})
db_waste_streams.delete_many({})
db_input_needs.delete_many({})

# Insert sample companies with closer locations
company1 = insert_company("AlphaChem", "NY")
company2 = insert_company("BetaPlastics", "NY")
company3 = insert_company("EcoSolvents", "PHI")

# Insert sample waste streams
waste1 = insert_waste_stream(company1.inserted_id, "Polyethylene", 1000, {"keywords": ["plastic", "polymer", "recyclable"]})
waste2 = insert_waste_stream(company2.inserted_id, "Polyethylene", 900, {"keywords": ["plastic", "polymer", "raw material"]})
waste3 = insert_waste_stream(company3.inserted_id, "Acetone", 500, {"keywords": ["solvent", "chemical", "flammable"]})

# Insert sample input needs
need1 = insert_input_need(company2.inserted_id, "Polyethylene", 800, {"keywords": ["plastic", "polymer", "raw material"]})
need2 = insert_input_need(company1.inserted_id, "Acetone", 200, {"keywords": ["solvent", "chemical", "cleaning"]})
need3 = insert_input_need(company3.inserted_id, "Polyethylene", 950, {"keywords": ["plastic", "polymer", "recyclable"]})

print("Sample data inserted into MongoDB.")
