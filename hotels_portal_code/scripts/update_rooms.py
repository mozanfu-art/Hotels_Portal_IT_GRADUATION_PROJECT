import firebase_admin
from firebase_admin import credentials, firestore
import random
import os

def update_all_rooms():
    """
    Updates all room documents across all hotels in the Firestore database.

    This function adds 'maxAdults' and 'maxChildren' fields with random
    integer values (1-4) and removes the 'maxGuests' field from each
    room document.
    """
    # --- Firebase Initialization ---
    # Important: Before running, ensure you have authenticated with Google Cloud.
    # 1. Install the gcloud CLI: https://cloud.google.com/sdk/docs/install
    # 2. Authenticate by running: gcloud auth application-default login
    SERVICE_ACCOUNT_KEY_PATH = os.path.join(os.path.dirname(__file__), 'serviceAccount.json')

    try:
        # Use application default credentials
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print("Firebase app initialized successfully.")
    except Exception as e:
        print(f"Error initializing Firebase app: {e}")
        print("Please ensure you have authenticated via 'gcloud auth application-default login'.")
        return

    db = firestore.client()
    updated_rooms_count = 0

    try:
        # Get all hotels
        rooms_ref = db.collection('rooms')
        room_docs = rooms_ref.stream()

        print("Starting room update process...")

            # Iterate through each room in the subcollection
        for room in room_docs:
                try:
                    room_data = room.to_dict()
                    room_id = room.id

                    types = [
    'King',
    'Queen',
    'Single',
    'Twins',
    'Suite',
    'Apartment',
    'Deluxe',
    'Business',
  ];
                        # Prepare the update payload
                    update_payload = {
                        'roomType': random.choice(types),
                        'type':firestore.DELETE_FIELD
                    }

                        # Update the room document
                    room.reference.update(update_payload)
                        
                    print(f"  - Updated room '{room_id}'")
                    updated_rooms_count += 1

                except Exception as e:
                    print(f"  - Error updating room '{room.id}': {e}")

    except Exception as e:
        print(f"An error occurred while fetching hotels: {e}")

    print(f"\nProcess complete. Total rooms updated: {updated_rooms_count}")

if __name__ == '__main__':
    update_all_rooms()