"""
MongoDB connection and schema setup for industrial symbiosis matchmaking.
"""
from pymongo import MongoClient

# Replace with your actual MongoDB URI
MONGO_URI = "mongodb://localhost:27017/synapse"
client = MongoClient(MONGO_URI)
db = client.get_database()

# Collections
db_companies = db["companies"]
db_waste_streams = db["waste_streams"]
db_input_needs = db["input_needs"]

# Example: Insert a company
def insert_company(name, location, **kwargs):
    company = {"name": name, "location": location}
    company.update(kwargs)
    return db_companies.insert_one(company)

# Example: Insert a waste stream
def insert_waste_stream(company_id, compound, quantity, properties=None):
    waste = {
        "company_id": company_id,
        "compound": compound,
        "quantity": quantity,
        "properties": properties or {}
    }
    return db_waste_streams.insert_one(waste)

# Example: Insert an input need
def insert_input_need(company_id, compound, quantity, properties=None):
    need = {
        "company_id": company_id,
        "compound": compound,
        "quantity": quantity,
        "properties": properties or {}
    }
    return db_input_needs.insert_one(need)
