import firebase_admin
from firebase_admin import credentials, firestore, auth
import random
from datetime import datetime
import os

# --- Configuration ---
# The script expects the service account key to be named 'serviceAccountKey.json'
# and located in the same directory as the script.
SERVICE_ACCOUNT_KEY_PATH = os.path.join(os.path.dirname(__file__), 'serviceAccount.json')

# --- Generic Data ---
FIRST_NAMES = ["Ali", "Fatima", "Omar", "Aisha", "Khalid", "Layla", "Yusuf", "Zainab", "Hassan", "Mariam"]
LAST_NAMES = ["Ahmed", "Ibrahim", "Hassan", "Osman", "Mohammed", "Abdullah", "Bakri", "Idris", "Salih", "Hamid"]
GENERIC_REVIEWS = [
    "A wonderful experience from start to finish. The staff was incredibly welcoming and attentive.",
    "The room was clean, comfortable, and had a great view. I would definitely stay here again.",
    "Excellent service and beautiful facilities. The location is perfect for exploring the city.",
    "We had a fantastic stay. The amenities were top-notch and the bed was very comfortable.",
    "Highly recommended! The hotel exceeded our expectations in every way.",
    "A lovely hotel with a friendly atmosphere. The food at the restaurant was also delicious.",
    "Clean, modern, and in a great location. What more could you ask for?",
    "The staff went above and beyond to make our stay special. Thank you!",
    "One of the best hotels I've stayed at. Everything was perfect.",
]


def initialize_firebase():
    """Initializes the Firebase Admin SDK."""
    try:
        if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
            print(f"Error: Service account key file not found at '{SERVICE_ACCOUNT_KEY_PATH}'")
            print("Please download it from your Firebase project settings and place it in the 'scripts' directory.")
            return None
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin SDK initialized successfully.")
        return firestore.client()
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        return None

def create_guests(db, num_guests=5):
    """Creates Firebase Auth users and corresponding Firestore guest documents."""
    print(f"\n--- Creating {num_guests} Dummy Guests (Auth + Firestore) ---")
    print("Default password for all new users is: password123")
    
    guests_collection = db.collection('guests')
    batch = db.batch()
    created_auth_users = []

    for i in range(num_guests):
        fname = random.choice(FIRST_NAMES)
        lname = random.choice(LAST_NAMES)
        email = f"{fname.lower()}.{lname.lower()}{random.randint(10, 99)}@example.com"
        password = "password123"
        
        try:
            # Step 1: Create the Firebase Authentication user
            user_record = auth.create_user(
                email=email,
                password=password,
                display_name=f"{fname} {lname}"
            )
            uid = user_record.uid
            created_auth_users.append(uid)
            print(f"  [Auth Created] Email: {email}, Pass: {password}, UID: {uid}")

            # Step 2: Prepare the Firestore document for this user
            guest_ref = guests_collection.document(uid)
            guest_data = {
                'guestId': uid,
                'FName': fname,
                'LName': lname,
                'email': email,
                'phone': f"09{random.randint(10000000, 99999999)}",
                'birthDate': None,
                'fcmToken': None,
                'role': 'guest',
                'active': True,
                'createdAt': datetime.now(),
                'updatedAt': datetime.now(),
                'favoriteHotelIds': []
            }
            batch.set(guest_ref, guest_data)
            print(f"  [Firestore Prepared] Guest document for {fname} {lname}")

        except auth.EmailAlreadyExistsError:
            print(f"  [Skipped] Auth user with email {email} already exists.")
        except Exception as e:
            print(f"  [Error] Failed to create auth user for {email}: {e}")

    try:
        # Step 3: Commit the batch to save all Firestore documents at once
        batch.commit()
        print(f"\nSuccessfully inserted {len(created_auth_users)} guest documents into Firestore.")
        return created_auth_users
    except Exception as e:
        print(f"\n[CRITICAL] Error committing Firestore batch: {e}")
        print("Rolling back created Firebase Authentication users...")
        for uid in created_auth_users:
            try:
                auth.delete_user(uid)
                print(f"  [Rollback] Deleted auth user with UID: {uid}")
            except Exception as rollback_error:
                print(f"  [CRITICAL] Failed to rollback auth user {uid}: {rollback_error}")
        return []

def create_reviews(db):
    """Fetches all hotels and adds 1 to 3 random reviews for each."""
    print("\n--- Creating Random Reviews for Hotels ---")
    hotels_collection = db.collection('hotels')
    guests_collection = db.collection('guests')
    reviews_collection = db.collection('reviews')
    batch = db.batch()

    try:
        # Fetch all hotels and guests
        hotels = list(hotels_collection.stream())
        guests = list(guests_collection.stream())

        if not hotels:
            print("No hotels found in the database. Cannot add reviews.")
            return
        if not guests:
            print("No guests found in the database. Cannot add reviews.")
            return

        print(f"Found {len(hotels)} hotels and {len(guests)} guests.")

        for hotel_doc in hotels:
            hotel_data = hotel_doc.to_dict()
            hotel_id = hotel_doc.id
            hotel_name = hotel_data.get('hotelName', 'Unknown Hotel')
            
            num_reviews = random.randint(1, 3)
            print(f"\nGenerating {num_reviews} review(s) for '{hotel_name}'...")

            for _ in range(num_reviews):
                # Select a random guest
                reviewer_doc = random.choice(guests)
                reviewer_data = reviewer_doc.to_dict()
                guest_id = reviewer_doc.id
                guest_name = f"{reviewer_data.get('FName', '')} {reviewer_data.get('LName', '')}".strip()

                # Generate review details
                review_ref = reviews_collection.document()
                review_data = {
                    'reviewId': review_ref.id,
                    'guestId': guest_id,
                    'hotelId': hotel_id,
                    'bookingId': f"DUMMY_BOOK_{random.randint(10000, 99999)}", # Placeholder booking ID
                    'hotelName': hotel_name,
                    'guestName': guest_name,
                    'starRate': float(random.randint(3, 5)), # Random positive rating (3, 4, or 5)
                    'review': random.choice(GENERIC_REVIEWS),
                    'createdAt': datetime.now(),
                    'updatedAt': datetime.now()
                }
                
                batch.set(review_ref, review_data)
                print(f"  [Prepared] Review by {guest_name} for {hotel_name} ({review_data['starRate']} stars)")

        # Commit all the new reviews in one batch
        batch.commit()
        print("\nSuccessfully inserted all generated reviews into the database.")

    except Exception as e:
        print(f"An error occurred while creating reviews: {e}")


def main():
    """Main function to run the script."""
    print("Starting script to populate Firestore with dummy data...")
    print("Ensure 'Email/Password' sign-in provider is enabled in Firebase Authentication.")
    db = initialize_firebase()
    
    if db:
        # Step 1: Create dummy guests with Auth accounts
        create_guests(db, 5)
        
        # Step 2: Create random reviews for existing hotels using any available guests
        create_reviews(db)
        
        print("\nScript finished.")
    else:
        print("\nScript aborted due to Firebase initialization failure.")


if __name__ == "__main__":
    main()