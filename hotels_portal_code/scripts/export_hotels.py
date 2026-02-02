import firebase_admin
from firebase_admin import credentials, firestore
import json
from datetime import datetime

# --- CONFIGURATION ---
SERVICE_ACCOUNT_KEY_PATH = 'scripts/serviceAccount.json'
OUTPUT_JSON_FILE = 'hotels_export.json'
COLLECTION_TO_EXPORT = 'hotels'

def initialize_firebase():
    """Initializes the Firebase Admin SDK."""
    try:
        # Check if the app is already initialized to prevent errors
        if not firebase_admin._apps:
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
            firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialized successfully.")
        return True
    except Exception as e:
        print(f"❌ Error initializing Firebase Admin SDK: {e}")
        print("Please ensure your 'serviceAccount.json' file is in the 'scripts' directory.")
        return False

def json_serializer(obj):
    """
    Custom JSON serializer to handle data types that are not natively
    serializable, such as Firestore Timestamps (which become datetime objects).
    """
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} is not JSON serializable")

def export_collection_to_json():
    """
    Connects to Firestore, fetches all documents from the specified collection,
    and writes them to a JSON file.
    """
    if not initialize_firebase():
        return

    db = firestore.client()
    collection_ref = db.collection(COLLECTION_TO_EXPORT)
    print(f"\n🚀 Starting export from '{COLLECTION_TO_EXPORT}' collection...")

    try:
        # Fetch all documents from the collection
        docs_stream = collection_ref.stream()
        
        all_documents = []
        doc_count = 0

        print("Fetching and processing documents...")
        for doc in docs_stream:
            doc_data = doc.to_dict()
            # Best practice: ensure the document's ID is included in the export
            doc_data['hotelId'] = doc.id
            all_documents.append(doc_data)
            doc_count += 1
            print(f"  - Processed document: {doc.id}")

        if doc_count == 0:
            print(f"🟡 No documents found in the '{COLLECTION_TO_EXPORT}' collection. No file created.")
            return

        # Write the list of dictionaries to a JSON file
        print(f"\nWriting {doc_count} documents to '{OUTPUT_JSON_FILE}'...")
        with open(OUTPUT_JSON_FILE, 'w', encoding='utf-8') as f:
            # Use json.dump with a custom default serializer for datetime objects
            json.dump(all_documents, f, ensure_ascii=False, indent=4, default=json_serializer)

        print("\n-----------------------------------------")
        print("✅ Success!")
        print(f"Exported {doc_count} hotel(s) to '{OUTPUT_JSON_FILE}'.")
        print("-----------------------------------------")

    except Exception as e:
        print("\n-----------------------------------------")
        print(f"❌ An unexpected error occurred during the export process: {e}")
        print("-----------------------------------------")

if __name__ == "__main__":
    export_collection_to_json()