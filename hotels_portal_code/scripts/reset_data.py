import os
import random
import uuid
import firebase_admin
from firebase_admin import credentials, firestore, auth, storage
from datetime import datetime

# --- CONFIGURATION ---
SERVICE_ACCOUNT_KEY_PATH = 'scripts/serviceAccount.json'
STORAGE_BUCKET = 'graduation-project-5f333.firebasestorage.app' # Replace with your actual storage bucket URL
IMAGE_SOURCE_FOLDER = 'scripts/pictures'
PASSWORD_FOR_ALL_ADMINS = "password123"

# --- Collections ---
HOTELS_COLLECTION = 'hotels'
ROOMS_COLLECTION = 'rooms'
ADMINS_COLLECTION = 'admins'
BOOKINGS_COLLECTION = 'bookings'
REVIEWS_COLLECTION = 'reviews'
GUESTS_COLLECTION = 'guests'
MINISTRY_REPORTS_COLLECTION = 'ministry_reports'


def initialize_firebase():
    """Initializes the Firebase Admin SDK."""
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred, {
            'storageBucket': STORAGE_BUCKET
        })
        print("✅ Firebase Admin SDK initialized successfully.")
        return True
    except Exception as e:
        print(f"❌ Error initializing Firebase Admin SDK: {e}")
        print("Ensure 'serviceAccount.json' is correctly placed in the 'scripts' directory.")
        return False

def delete_collection(coll_ref, batch_size=500):
    """Deletes all documents in a collection in batches."""
    try:
        docs = coll_ref.limit(batch_size).stream()
        deleted = 0
        batch = firestore.client().batch()
        for doc in docs:
            print(f"  - Scheduling deletion for doc: {doc.id}")
            batch.delete(doc.reference)
            deleted += 1

        if deleted == 0:
            return True # No more documents to delete

        batch.commit()
        print(f"  ...deleted {deleted} documents.")
        return delete_collection(coll_ref, batch_size)
    except Exception as e:
        print(f"❌ Error deleting collection {coll_ref.id}: {e}")
        return False


def clear_all_data():
    """Clears all relevant data from Firestore, Authentication, and Storage."""
    db = firestore.client()
    print("\n--- 🚀 Starting Data Deletion Process ---")

    # Clear Firestore Collections
    collections_to_clear = [
        HOTELS_COLLECTION, ROOMS_COLLECTION, ADMINS_COLLECTION,
        GUESTS_COLLECTION, BOOKINGS_COLLECTION, REVIEWS_COLLECTION,
        MINISTRY_REPORTS_COLLECTION
    ]
    for coll in collections_to_clear:
        print(f"\nClearing '{coll}' collection...")
        coll_ref = db.collection(coll)
        delete_collection(coll_ref)

    # Clear Firebase Authentication Users
    print("\nClearing Firebase Authentication users...")
    try:
        for user in auth.list_users().iterate_all():
            print(f"  - Deleting user: {user.uid} ({user.email})")
            auth.delete_user(user.uid)
        print("✅ All authentication users deleted.")
    except Exception as e:
        print(f"❌ Error deleting auth users: {e}")

    # Clear Firebase Storage
    print("\nClearing Firebase Storage 'hotels/' folder...")
    bucket = storage.bucket()
    blobs = bucket.list_blobs(prefix="hotels/")
    try:
        for blob in blobs:
            print(f"  - Deleting file: {blob.name}")
            blob.delete()
        print("✅ Storage 'hotels/' folder cleared.")
    except Exception as e:
        print(f"❌ Error clearing storage: {e}")

    print("\n--- ✅ Data Deletion Complete ---\n")


def get_random_image_paths(count=5):
    """Gets a list of random image file paths from the source folder."""
    all_images = []
    for root, _, files in os.walk(IMAGE_SOURCE_FOLDER):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg', '.jfif', '.webp')):
                all_images.append(os.path.join(root, file))
    return random.sample(all_images, min(count, len(all_images)))


def upload_image_and_get_url(file_path, destination_path):
    """Uploads an image to Firebase Storage and returns the public URL."""
    try:
        bucket = storage.bucket()
        blob = bucket.blob(destination_path)
        blob.upload_from_filename(file_path)
        blob.make_public()
        return blob.public_url
    except Exception as e:
        print(f"⚠️ Could not upload image {file_path}: {e}")
        return None

HOTEL_DATA = [
    # Original Data
    {
        "hotelName": "Grand Khartoum Hotel",
        "hotelState": "Khartoum",
        "hotelCity": "Khartoum",
        "hotelAddress": "123 Nile Street, Khartoum",
        "hotelEmail": "contact@grandkhartoum.com",
        "hotelPhone": "+249 123 456 789",
        "hotelDescription": "A luxurious 5-star hotel offering world-class amenities and breathtaking views of the Nile.",
        "starRate": 5,
        "approved": True,
        "amenities": ["Free WiFi", "Swimming Pool", "Fitness Center", "Restaurant", "Spa", "Parking"],
        "restaurants": [{"name": "Nile Grill", "location": "Ground Floor"}],
        "conferenceRoomsCount": 5,
        "admin": {"fName": "Hotel", "lName": "Manager1", "email_prefix": "manager.khartoum"},
        "rooms": [
            {"roomType": "Standard Queen", "pricePerNight": 120.0, "maxGuests": 2, "description": "A comfortable room with a queen-sized bed.", "amenities": ["WiFi", "TV", "AC"]},
            {"roomType": "Deluxe King", "pricePerNight": 250.0, "maxGuests": 3, "description": "Spacious deluxe room with a king-sized bed and city view.", "amenities": ["WiFi", "TV", "AC", "Mini Bar"]},
            {"roomType": "Nile View Suite", "pricePerNight": 450.0, "maxGuests": 4, "description": "An executive suite with a separate living area and a stunning Nile view.", "amenities": ["WiFi", "TV", "AC", "Mini Bar", "Balcony"]},
        ]
    },
    {
        "hotelName": "Red Sea Resort",
        "hotelState": "Red Sea",
        "hotelCity": "Port Sudan",
        "hotelAddress": "456 Beach Road, Port Sudan",
        "hotelEmail": "info@redsearesort.com",
        "hotelPhone": "+249 987 654 321",
        "hotelDescription": "Escape to our beautiful resort on the shores of the Red Sea. Perfect for diving and relaxation.",
        "starRate": 4,
        "approved": True,
        "amenities": ["Free WiFi", "Swimming Pool", "Beach Access", "Dive Center", "Restaurant"],
        "restaurants": [{"name": "Coral Restaurant", "location": "Beachfront"}],
        "conferenceRoomsCount": 2,
        "admin": {"fName": "Resort", "lName": "Director", "email_prefix": "director.portsudan"},
        "rooms": [
            {"roomType": "Standard Double", "pricePerNight": 150.0, "maxGuests": 2, "description": "Cozy room with two single beds.", "amenities": ["AC", "TV"]},
            {"roomType": "Ocean View Bungalow", "pricePerNight": 300.0, "maxGuests": 3, "description": "Private bungalow with a direct view of the Red Sea.", "amenities": ["AC", "TV", "Patio"]},
        ]
    },
    {
        "hotelName": "Gezira Palace",
        "hotelState": "Gezira",
        "hotelCity": "Wad Madani",
        "hotelAddress": "789 Central Avenue, Wad Madani",
        "hotelEmail": "bookings@gezirapalace.com",
        "hotelPhone": "+249 555 123 456",
        "hotelDescription": "Experience traditional Sudanese hospitality in the heart of Gezira state.",
        "starRate": 3,
        "approved": False,
        "amenities": ["Free WiFi", "Restaurant", "Garden"],
        "restaurants": [{"name": "Al-Waha Restaurant", "location": "Lobby"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Gezira", "lName": "Owner", "email_prefix": "owner.gezira"},
        "rooms": [
            {"roomType": "Single Room", "pricePerNight": 80.0, "maxGuests": 1, "description": "A simple and clean room for a single traveler.", "amenities": ["Fan", "WiFi"]},
            {"roomType": "Family Room", "pricePerNight": 130.0, "maxGuests": 4, "description": "A large room suitable for families.", "amenities": ["AC", "TV", "WiFi"]},
        ]
    },
    
    {
        "hotelName": "Gedaref Hotel",
        "hotelState": "Gedaref",
        "hotelCity": "Al Qadarif",
        "hotelAddress": "Main Street, Al Qadarif, Gedaref, Sudan",
        "hotelEmail": "info@gedarefhotel.com",
        "hotelPhone": "+249 555 111 222",
        "hotelDescription": "City hotel in Gedaref offering standard rooms and dining.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Gedaref Eatery", "location": "Ground Floor"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Manager", "lName": "Gedaref", "email_prefix": "manager.gedaref"},
        "rooms": [
            {"roomType": "Standard Single", "pricePerNight": 75.0, "maxGuests": 1, "description": "A clean and simple room for one guest.", "amenities": ["WiFi", "Fan"]},
            {"roomType": "Standard Double", "pricePerNight": 110.0, "maxGuests": 2, "description": "A comfortable room for two guests with a double bed.", "amenities": ["WiFi", "AC", "TV"]}
        ]
    },
    {
        "hotelName": "Kosti Grand Hotel",
        "hotelState": "White Nile",
        "hotelCity": "Kosti",
        "hotelAddress": "Main Street, Kosti, White Nile, Sudan",
        "hotelEmail": "info@kostigrand.com",
        "hotelPhone": "+249 555 333 444",
        "hotelDescription": "A central city hotel in Kosti, perfect for business travelers.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Meeting Rooms"],
        "restaurants": [{"name": "Nile Bites", "location": "Lobby"}],
        "conferenceRoomsCount": 2,
        "admin": {"fName": "Manager", "lName": "Kosti", "email_prefix": "manager.kosti"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 90.0, "maxGuests": 2, "description": "Well-equipped standard room.", "amenities": ["WiFi", "AC"]},
            {"roomType": "Business Suite", "pricePerNight": 160.0, "maxGuests": 2, "description": "A suite with a dedicated workspace.", "amenities": ["WiFi", "AC", "TV", "Desk"]}
        ]
    },
    {
        "hotelName": "Rabak Hotel",
        "hotelState": "White Nile",
        "hotelCity": "Rabak",
        "hotelAddress": "Main Street, Rabak, White Nile, Sudan",
        "hotelEmail": "contact@rabakhotel.com",
        "hotelPhone": "+249 555 555 666",
        "hotelDescription": "A reliable hotel serving travelers and visitors to Rabak and nearby industrial areas.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "The Traveler's Table", "location": "Main Building"}],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "Admin", "lName": "Rabak", "email_prefix": "admin.rabak"},
        "rooms": [
            {"roomType": "Single", "pricePerNight": 70.0, "maxGuests": 1, "description": "An affordable room for a single traveler.", "amenities": ["WiFi", "Fan"]},
            {"roomType": "Double", "pricePerNight": 100.0, "maxGuests": 2, "description": "A comfortable room for two.", "amenities": ["WiFi", "AC"]}
        ]
    },
    {
        "hotelName": "Kadugli Hotel",
        "hotelState": "South Kordofan",
        "hotelCity": "Kadugli",
        "hotelAddress": "Main Street, Kadugli, South Kordofan, Sudan",
        "hotelEmail": "stay@kaduglihotel.com",
        "hotelPhone": "+249 555 777 888",
        "hotelDescription": "The main guesthouse in Kadugli, offering essential amenities for visitors to the region.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Local Flavors", "location": "Ground Floor"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Kadugli", "lName": "Manager", "email_prefix": "manager.kadugli"},
        "rooms": [
            {"roomType": "Twin Room", "pricePerNight": 95.0, "maxGuests": 2, "description": "Room with two single beds.", "amenities": ["AC", "WiFi"]},
            {"roomType": "King Room", "pricePerNight": 140.0, "maxGuests": 2, "description": "Spacious room with a king bed.", "amenities": ["AC", "WiFi", "TV"]}
        ]
    },
    {
        "hotelName": "Merowe Tourist Village",
        "hotelState": "Northern",
        "hotelCity": "Merowe",
        "hotelAddress": "Main Street, Merowe, Northern, Sudan",
        "hotelEmail": "info@merowetours.com",
        "hotelPhone": "+249 999 902 299",
        "hotelDescription": "Resort-style tourist village catering to visitors exploring the nearby archaeological sites.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "Restaurant", "Tour desk", "Garden"],
        "restaurants": [{"name": "Nubian Kitchen", "location": "Main Hall"}],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "Tourism", "lName": "Director", "email_prefix": "director.merowe"},
        "rooms": [
            {"roomType": "Chalet", "pricePerNight": 180.0, "maxGuests": 3, "description": "A private chalet with traditional decor.", "amenities": ["AC", "Patio"]},
            {"roomType": "Standard Room", "pricePerNight": 110.0, "maxGuests": 2, "description": "A comfortable room with modern amenities.", "amenities": ["AC", "WiFi"]}
        ]
    },
    {
        "hotelName": "Baasher Palace Hotel",
        "hotelState": "Red Sea",
        "hotelCity": "Port Sudan",
        "hotelAddress": "Main Street, Port Sudan, Red Sea, Sudan",
        "hotelEmail": "info@baasherpalace.com",
        "hotelPhone": "+249 555 999 000",
        "hotelDescription": "A historic and charming hotel located near the Port Sudan seafront, offering a glimpse into the city's past.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Pool"],
        "restaurants": [{"name": "The Palace Dining", "location": "Courtyard"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Baasher", "lName": "Manager", "email_prefix": "manager.baasher"},
        "rooms": [
            {"roomType": "Classic Double", "pricePerNight": 130.0, "maxGuests": 2, "description": "A room with classic decor and a comfortable double bed.", "amenities": ["WiFi", "AC"]},
            {"roomType": "Sea View Room", "pricePerNight": 190.0, "maxGuests": 2, "description": "Enjoy beautiful views of the sea from your room.", "amenities": ["WiFi", "AC", "Balcony"]}
        ]
    },
    {
        "hotelName": "Grand Sahil Hotel",
        "hotelState": "Red Sea",
        "hotelCity": "Port Sudan",
        "hotelAddress": "Port Sudan Seafront",
        "hotelEmail": "info@grandsahil.com",
        "hotelPhone": "+249 187 199 411",
        "hotelDescription": "A modern and elegant hotel situated right on the Port Sudan seafront, offering excellent services.",
        "starRate": 4,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Gym", "Business Center"],
        "restaurants": [{"name": "Sahil Seafood", "location": "Terrace"}],
        "conferenceRoomsCount": 3,
        "admin": {"fName": "Sahil", "lName": "Manager", "email_prefix": "manager.sahil"},
        "rooms": [
            {"roomType": "City View King", "pricePerNight": 220.0, "maxGuests": 2, "description": "Modern room with a king bed and city views.", "amenities": ["WiFi", "AC", "TV"]},
            {"roomType": "Seafront Suite", "pricePerNight": 350.0, "maxGuests": 3, "description": "Luxurious suite with panoramic views of the Red Sea.", "amenities": ["WiFi", "AC", "TV", "Living Area"]}
        ]
    },
    {
        "hotelName": "Zalingei Hotel",
        "hotelState": "Central Darfur",
        "hotelCity": "Zalingei",
        "hotelAddress": "Main Street, Zalingei, Central Darfur, Sudan",
        "hotelEmail": "info@zalingeihotel.com",
        "hotelPhone": "+249 555 111 333",
        "hotelDescription": "The principal hotel in Zalingei, providing essential accommodation for regional visitors and officials.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Darfur Kitchen", "location": "Main Building"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Manager", "lName": "Zalingei", "email_prefix": "manager.zalingei"},
        "rooms": [
            {"roomType": "Standard Room", "pricePerNight": 85.0, "maxGuests": 2, "description": "A basic but comfortable room.", "amenities": ["Fan", "WiFi"]},
            {"roomType": "AC Room", "pricePerNight": 125.0, "maxGuests": 2, "description": "An upgraded room with air conditioning.", "amenities": ["AC", "WiFi"]}
        ]
    },
    {
        "hotelName": "Coral Port Sudan Hotel",
        "hotelState": "Red Sea",
        "hotelCity": "Port Sudan",
        "hotelAddress": "Harbour Entrance, Port Sudan, Red Sea, Sudan",
        "hotelEmail": "reservations@coralportsudan.com",
        "hotelPhone": "+249 555 222 444",
        "hotelDescription": "A premium seafront hotel located at the entrance of Port Sudan harbour, with exceptional views.",
        "starRate": 4,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Pool", "Meeting Rooms"],
        "restaurants": [{"name": "The Harbour View", "location": "Top Floor"}],
        "conferenceRoomsCount": 4,
        "admin": {"fName": "Hotel", "lName": "Director", "email_prefix": "director.coralps"},
        "rooms": [
            {"roomType": "Superior Room", "pricePerNight": 250.0, "maxGuests": 2, "description": "A well-appointed room with luxury amenities.", "amenities": ["WiFi", "AC", "Mini Bar"]},
            {"roomType": "Executive Suite", "pricePerNight": 400.0, "maxGuests": 3, "description": "A large suite with a living area and premium services.", "amenities": ["WiFi", "AC", "Mini Bar", "Lounge Access"]}
        ]
    },
    {
        "hotelName": "El Fula Hotel",
        "hotelState": "West Kordofan",
        "hotelCity": "El Fula",
        "hotelAddress": "Main Street, El Fula, West Kordofan, Sudan",
        "hotelEmail": "info@elfulahotel.com",
        "hotelPhone": "+249 555 666 888",
        "hotelDescription": "A representative hotel in West Kordofan, serving the needs of local and business travelers.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Kordofan Grill", "location": "Ground Floor"}],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "ElFula", "lName": "Admin", "email_prefix": "admin.elfula"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 90.0, "maxGuests": 2, "description": "A comfortable and clean room.", "amenities": ["WiFi", "AC"]}
        ]
    },
    {
        "hotelName": "Zanobia Hotel",
        "hotelState": "North Kordofan",
        "hotelCity": "El Obeid",
        "hotelAddress": "Main Street, El Obeid, North Kordofan, Sudan",
        "hotelEmail": "contact@zanobiahotel.com",
        "hotelPhone": "+249 555 123 789",
        "hotelDescription": "A local mid-range hotel in El Obeid offering affordable and comfortable stays.",
        "starRate": 2,
        "approved": True,
        "amenities": ["WiFi", "AC"],
        "restaurants": [],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "Zanobia", "lName": "Manager", "email_prefix": "manager.zanobia"},
        "rooms": [
            {"roomType": "Economy Single", "pricePerNight": 60.0, "maxGuests": 1, "description": "Basic room for budget travelers.", "amenities": ["Fan"]},
            {"roomType": "AC Double", "pricePerNight": 100.0, "maxGuests": 2, "description": "A double room with air conditioning.", "amenities": ["AC", "WiFi"]}
        ]
    },
    {
        "hotelName": "Kassala Hotel",
        "hotelState": "Kassala",
        "hotelCity": "Kassala",
        "hotelAddress": "Main Street, Kassala, Kassala, Sudan",
        "hotelEmail": "bookings@kassalahotel.com",
        "hotelPhone": "+249 555 456 123",
        "hotelDescription": "The main city hotel used by travelers visiting the beautiful Taka Mountains.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Tour Assistance"],
        "restaurants": [{"name": "Taka View Restaurant", "location": "Rooftop"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Manager", "lName": "Kassala", "email_prefix": "manager.kassala"},
        "rooms": [
            {"roomType": "Standard Twin", "pricePerNight": 115.0, "maxGuests": 2, "description": "Comfortable room with two beds.", "amenities": ["WiFi", "AC"]},
            {"roomType": "Mountain View Room", "pricePerNight": 175.0, "maxGuests": 2, "description": "Room with a scenic view of the Taka Mountains.", "amenities": ["WiFi", "AC", "Balcony"]}
        ]
    },
    {
        "hotelName": "5M Hotel",
        "hotelState": "Khartoum",
        "hotelCity": "Khartoum",
        "hotelAddress": "Katrina Street, Khartoum",
        "hotelEmail": "info@5mhotel.com",
        "hotelPhone": "+249 555 789 123",
        "hotelDescription": "A budget-friendly hotel located conveniently in Khartoum city centre.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC"],
        "restaurants": [],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "5M", "lName": "Admin", "email_prefix": "admin.5m"},
        "rooms": [
            {"roomType": "Budget Double", "pricePerNight": 80.0, "maxGuests": 2, "description": "An affordable room for two.", "amenities": ["WiFi", "AC"]}
        ]
    },
    {
        "hotelName": "Damazin Grand Hotel",
        "hotelState": "Blue Nile",
        "hotelCity": "Damazin",
        "hotelAddress": "Main Street, Damazin, Blue Nile, Sudan",
        "hotelEmail": "reservations@damazingrand.com",
        "hotelPhone": "+249 555 987 654",
        "hotelDescription": "The primary local hotel for business and government visitors in the Blue Nile state.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Blue Nile Dining", "location": "Ground Floor"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Damazin", "lName": "Manager", "email_prefix": "manager.damazin"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 100.0, "maxGuests": 2, "description": "A standard room for visitors.", "amenities": ["WiFi", "AC", "TV"]}
        ]
    },
    {
        "hotelName": "Al Salam Rotana Hotel",
        "hotelState": "Khartoum",
        "hotelCity": "Khartoum",
        "hotelAddress": "Africa Road, Khartoum",
        "hotelEmail": "reservation@alsalamhotel.com",
        "hotelPhone": "+249 187 007 777",
        "hotelDescription": "An international 5-star hotel with extensive conference facilities, a large pool, and multiple fine dining options.",
        "starRate": 5,
        "approved": True,
        "amenities": ["Pool", "Gym", "Conference Rooms", "Restaurant", "WiFi", "AC", "Spa"],
        "restaurants": [{"name": "Al Nuba Restaurant", "location": "Lobby"}, {"name": "City Cafe", "location": "Poolside"}],
        "conferenceRoomsCount": 8,
        "admin": {"fName": "AlSalam", "lName": "Director", "email_prefix": "director.alsalam"},
        "rooms": [
            {"roomType": "Classic King", "pricePerNight": 300.0, "maxGuests": 2, "description": "Elegant room with a king-sized bed.", "amenities": ["WiFi", "AC", "Mini Bar"]},
            {"roomType": "Club Rotana Suite", "pricePerNight": 550.0, "maxGuests": 3, "description": "A premium suite with exclusive lounge access.", "amenities": ["WiFi", "AC", "Mini Bar", "Lounge Access"]}
        ]
    },
    {
        "hotelName": "El Geneina Hotel",
        "hotelState": "West Darfur",
        "hotelCity": "El Geneina",
        "hotelAddress": "Main Street, El Geneina, West Darfur, Sudan",
        "hotelEmail": "info@elgeneinahotel.com",
        "hotelPhone": "+249 555 321 654",
        "hotelDescription": "The main hotel in El Geneina city, offering mid-range rooms for regional travelers and NGO staff.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "The Oasis", "location": "Ground Floor"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Geneina", "lName": "Admin", "email_prefix": "admin.geneina"},
        "rooms": [
            {"roomType": "Standard Twin", "pricePerNight": 90.0, "maxGuests": 2, "description": "A functional room with two beds.", "amenities": ["AC", "WiFi"]}
        ]
    },
    {
        "hotelName": "Mirak Hotel Suites",
        "hotelState": "Red Sea",
        "hotelCity": "Port Sudan",
        "hotelAddress": "Corniche Street, Port Sudan, Red Sea, Sudan",
        "hotelEmail": "reservations@miraksuites.com",
        "hotelPhone": "+249 555 789 987",
        "hotelDescription": "Boutique suites in Port Sudan, popular with tourists looking for comfort and style on the Red Sea coast.",
        "starRate": 4,
        "approved": True,
        "amenities": ["WiFi", "AC", "Kitchenette", "Sea View"],
        "restaurants": [],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "Mirak", "lName": "Owner", "email_prefix": "owner.mirak"},
        "rooms": [
            {"roomType": "Junior Suite", "pricePerNight": 220.0, "maxGuests": 2, "description": "A stylish suite with a small kitchen.", "amenities": ["WiFi", "AC", "Kitchenette"]},
            {"roomType": "Family Suite", "pricePerNight": 320.0, "maxGuests": 4, "description": "A two-bedroom suite perfect for families.", "amenities": ["WiFi", "AC", "Kitchenette"]}
        ]
    },
    {
        "hotelName": "Grand Hotel El Obeid",
        "hotelState": "North Kordofan",
        "hotelCity": "El Obeid",
        "hotelAddress": "Central Square, El Obeid, North Kordofan, Sudan",
        "hotelEmail": "info@grandelobeid.com",
        "hotelPhone": "+249 555 654 789",
        "hotelDescription": "A prominent city hotel serving travelers and business visitors in El Obeid.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Event Hall"],
        "restaurants": [{"name": "Kordofan Kitchen", "location": "Lobby"}],
        "conferenceRoomsCount": 2,
        "admin": {"fName": "ElObeid", "lName": "Manager", "email_prefix": "manager.elobeid"},
        "rooms": [
            {"roomType": "Standard Double", "pricePerNight": 110.0, "maxGuests": 2, "description": "A comfortable double room.", "amenities": ["WiFi", "AC"]},
        ]
    },
    {
        "hotelName": "Corinthia Hotel Khartoum",
        "hotelState": "Khartoum",
        "hotelCity": "Khartoum",
        "hotelAddress": "Nile Road, Khartoum",
        "hotelEmail": "khartoum@corinthia.com",
        "hotelPhone": "+249 183 777 666",
        "hotelDescription": "Five-star landmark hotel at the confluence of the Blue and White Nile. Features multiple restaurants, a full-service spa, a large outdoor pool, and extensive conference facilities.",
        "starRate": 5,
        "approved": True,
        "amenities": ["Spa", "Pool", "Gym", "Restaurant", "WiFi", "AC", "Business Center"],
        "restaurants": [{"name": "Rickshaw Restaurant", "location": "18th Floor"}, {"name": "Le Grill", "location": "Lobby"}],
        "conferenceRoomsCount": 6,
        "admin": {"fName": "Corinthia", "lName": "GM", "email_prefix": "gm.corinthia"},
        "rooms": [
            {"roomType": "Deluxe City View", "pricePerNight": 350.0, "maxGuests": 2, "description": "Luxurious room with stunning city views.", "amenities": ["WiFi", "AC", "Mini Bar"]},
            {"roomType": "Executive Nile View", "pricePerNight": 500.0, "maxGuests": 2, "description": "High-floor room with panoramic Nile views and lounge access.", "amenities": ["WiFi", "AC", "Mini Bar", "Lounge Access"]},
            {"roomType": "Presidential Suite", "pricePerNight": 1500.0, "maxGuests": 4, "description": "The pinnacle of luxury with a private dining room and butler service.", "amenities": ["All-inclusive"]}
        ]
    },
    {
        "hotelName": "Sennar Hotel",
        "hotelState": "Sennar",
        "hotelCity": "Sennar",
        "hotelAddress": "Main Street, Sennar, Sennar, Sudan",
        "hotelEmail": "info@sennarhotel.com",
        "hotelPhone": "+249 555 111 555",
        "hotelDescription": "A practical city hotel used by local travelers and those visiting the Sennar Dam.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Dam View Diner", "location": "Main Building"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Sennar", "lName": "Admin", "email_prefix": "admin.sennar"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 80.0, "maxGuests": 2, "description": "A clean and functional room.", "amenities": ["WiFi", "AC"]}
        ]
    },
    {
        "hotelName": "Khartoum Regency Hotel",
        "hotelState": "Khartoum",
        "hotelCity": "Khartoum",
        "hotelAddress": "Khalifa Street, Khartoum",
        "hotelEmail": "reservations@khartoumregency.com",
        "hotelPhone": "+249 555 222 666",
        "hotelDescription": "A well-known business hotel in central Khartoum, featuring conference facilities and an on-site restaurant.",
        "starRate": 4,
        "approved": True,
        "amenities": ["WiFi", "Restaurant", "Conference Rooms", "AC"],
        "restaurants": [{"name": "The Diplomat", "location": "Lobby"}],
        "conferenceRoomsCount": 4,
        "admin": {"fName": "Regency", "lName": "Manager", "email_prefix": "manager.regency"},
        "rooms": [
            {"roomType": "Business Class", "pricePerNight": 180.0, "maxGuests": 2, "description": "A room designed for the business traveler.", "amenities": ["WiFi", "AC", "Desk"]},
            {"roomType": "Junior Suite", "pricePerNight": 280.0, "maxGuests": 3, "description": "A larger suite with a small sitting area.", "amenities": ["WiFi", "AC", "Mini Bar"]}
        ]
    },
    {
        "hotelName": "Ed Daein Hotel",
        "hotelState": "East Darfur",
        "hotelCity": "Ed Daein",
        "hotelAddress": "Main Street, Ed Daein, East Darfur, Sudan",
        "hotelEmail": "info@eddaeinhotel.com",
        "hotelPhone": "+249 555 333 777",
        "hotelDescription": "A local hotel used for regional travel in East Darfur, providing essential services.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "Darfur Delights", "location": "Ground Floor"}],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "EdDaein", "lName": "Clerk", "email_prefix": "clerk.eddaein"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 75.0, "maxGuests": 2, "description": "A basic room for travelers.", "amenities": ["Fan", "WiFi"]}
        ]
    },
    {
        "hotelName": "Grand Hotel Atbara",
        "hotelState": "River Nile",
        "hotelCity": "Atbara",
        "hotelAddress": "Main Street, Atbara, River Nile, Sudan",
        "hotelEmail": "contact@grandatbara.com",
        "hotelPhone": "+249 555 444 888",
        "hotelDescription": "A central city hotel in the historic railway city of Atbara, used by travelers and business visitors.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "The Railway Club", "location": "Ground Floor"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "Atbara", "lName": "Admin", "email_prefix": "admin.atbara"},
        "rooms": [
            {"roomType": "Standard Double", "pricePerNight": 100.0, "maxGuests": 2, "description": "A comfortable room for two.", "amenities": ["AC", "WiFi", "TV"]}
        ]
    },
    {
        "hotelName": "Ewa Hotel & Apartments",
        "hotelState": "Khartoum",
        "hotelCity": "Khartoum",
        "hotelAddress": "Kafouri Area, Khartoum",
        "hotelEmail": "bookings@ewahotel.com",
        "hotelPhone": "+249 555 555 999",
        "hotelDescription": "An apartment-style hotel with units suitable for both short-term and long-stay guests.",
        "starRate": 4,
        "approved": True,
        "amenities": ["WiFi", "Kitchenette", "AC", "Pool", "Gym"],
        "restaurants": [],
        "conferenceRoomsCount": 0,
        "admin": {"fName": "Ewa", "lName": "Manager", "email_prefix": "manager.ewa"},
        "rooms": [
            {"roomType": "Studio Apartment", "pricePerNight": 150.0, "maxGuests": 2, "description": "A self-contained studio with a kitchenette.", "amenities": ["WiFi", "AC", "Kitchenette"]},
            {"roomType": "One-Bedroom Apartment", "pricePerNight": 220.0, "maxGuests": 3, "description": "A spacious apartment with a separate bedroom.", "amenities": ["WiFi", "AC", "Kitchenette", "Living Room"]}
        ]
    },
    {
        "hotelName": "Imperial Hotel Wad Madani",
        "hotelState": "Gezira",
        "hotelCity": "Wad Madani",
        "hotelAddress": "Al Debaga St, Wad Madani",
        "hotelEmail": "gasimalfransawi@yahoo.com",
        "hotelPhone": "+249 123 840 500",
        "hotelDescription": "A well-regarded local hotel located near the University of Gezira.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "The Imperial Court", "location": "Lobby"}],
        "conferenceRoomsCount": 2,
        "admin": {"fName": "Imperial", "lName": "Clerk", "email_prefix": "clerk.imperial"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 100.0, "maxGuests": 2, "description": "A clean and comfortable room.", "amenities": ["WiFi", "AC", "TV"]}
        ]
    },
    {
        "hotelName": "Nyala Grand Hotel",
        "hotelState": "South Darfur",
        "hotelCity": "Nyala",
        "hotelAddress": "Main Street, Nyala, South Darfur, Sudan",
        "hotelEmail": "info@nyalagrand.com",
        "hotelPhone": "+249 555 666 111",
        "hotelDescription": "The key hotel in the Nyala region, providing reliable services for visitors and organizations.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant", "Conference Rooms"],
        "restaurants": [{"name": "Darfur Hall", "location": "Main Building"}],
        "conferenceRoomsCount": 3,
        "admin": {"fName": "Nyala", "lName": "Manager", "email_prefix": "manager.nyala"},
        "rooms": [
            {"roomType": "Standard Room", "pricePerNight": 110.0, "maxGuests": 2, "description": "A dependable room for travelers.", "amenities": ["AC", "WiFi"]},
            {"roomType": "Business Room", "pricePerNight": 150.0, "maxGuests": 2, "description": "A room with a dedicated workspace.", "amenities": ["AC", "WiFi", "Desk"]}
        ]
    },
    {
        "hotelName": "El Fasher Grand Hotel",
        "hotelState": "North Darfur",
        "hotelCity": "Al-Fashir",
        "hotelAddress": "Main Street, Al-Fashir, North Darfur, Sudan",
        "hotelEmail": "info@elfashergrand.com",
        "hotelPhone": "+249 555 777 222",
        "hotelDescription": "A central hotel in Al-Fashir, frequently used by NGOs and regional travelers.",
        "starRate": 3,
        "approved": True,
        "amenities": ["WiFi", "AC", "Restaurant"],
        "restaurants": [{"name": "The Meeting Point", "location": "Lobby"}],
        "conferenceRoomsCount": 1,
        "admin": {"fName": "ElFasher", "lName": "Manager", "email_prefix": "manager.elfasher"},
        "rooms": [
            {"roomType": "Standard", "pricePerNight": 95.0, "maxGuests": 2, "description": "A standard room for visitors.", "amenities": ["AC", "WiFi"]}
        ]
    }
]



def populate_data():
    """Main function to populate the database with hotel data."""
    db = firestore.client()
    print("--- 🚀 Starting Data Population Process ---")

    # Get a list of available image files
    available_images = get_random_image_paths(count=100) # Get a large pool of images
    if not available_images:
        print("⚠️ Warning: No images found in the source folder. Hotels and rooms will have no photos.")

    hotel_count = 0
    for hotel_data in HOTEL_DATA:
        hotel_count += 1
        print(f"\n--- Processing Hotel {hotel_count}/{len(HOTEL_DATA)}: {hotel_data['hotelName']} ---")

        try:
            # 1. Create Admin User in Firebase Auth
            admin_email = f"{hotel_data['admin']['email_prefix']}@hotelportal.com"
            print(f"  Creating admin auth user: {admin_email}")
            admin_user = auth.create_user(
                email=admin_email,
                password=PASSWORD_FOR_ALL_ADMINS,
                display_name=f"{hotel_data['admin']['fName']} {hotel_data['admin']['lName']}"
            )

            # 2. Create Hotel Document
            hotel_id = db.collection(HOTELS_COLLECTION).document().id
            hotel_doc_ref = db.collection(HOTELS_COLLECTION).document(hotel_id)

            new_hotel = {
                "hotelId": hotel_id,
                "adminId": admin_user.uid,
                "createdAt": datetime.now(),
                "updatedAt": datetime.now(),
                "images": [], # Will be updated after upload
                **{k: v for k, v in hotel_data.items() if k not in ['admin', 'rooms']}
            }
            hotel_doc_ref.set(new_hotel)
            print(f"  Created hotel document with ID: {hotel_id}")

            # 3. Create Admin Document in Firestore
            admin_doc_ref = db.collection(ADMINS_COLLECTION).document(admin_user.uid)
            new_admin = {
                "adminId": admin_user.uid,
                "fName": hotel_data['admin']['fName'],
                "lName": hotel_data['admin']['lName'],
                "email": admin_email,
                "hotelId": hotel_id,
                "hotelName": hotel_data['hotelName'],
                "hotelCity": hotel_data['hotelCity'],
                "hotelState": hotel_data['hotelState'],
                "hotelAddress": hotel_data['hotelAddress'],
                "role": "hotel admin",
                "active": True,
                "createdAt": datetime.now(),
                "updatedAt": datetime.now(),
            }
            admin_doc_ref.set(new_admin)
            print(f"  Created admin document for UID: {admin_user.uid}")

            # 4. Upload Hotel Images
            hotel_image_urls = []
            if available_images:
                images_to_upload = random.sample(available_images, min(5, len(available_images)))
                print(f"  Uploading {len(images_to_upload)} hotel images...")
                for image_path in images_to_upload:
                    file_name = os.path.basename(image_path)
                    destination = f"hotels/{hotel_id}/images/{uuid.uuid4()}_{file_name}"
                    url = upload_image_and_get_url(image_path, destination)
                    if url:
                        hotel_image_urls.append(url)
                hotel_doc_ref.update({"images": hotel_image_urls})
                print(f"  ...updated hotel with {len(hotel_image_urls)} image URLs.")

            # 5. Create Rooms and Upload Room Images
            if 'rooms' in hotel_data:
                print(f"  Creating {len(hotel_data['rooms'])} room types...")
                for room_data in hotel_data['rooms']:
                    room_id = db.collection(ROOMS_COLLECTION).document().id
                    room_doc_ref = db.collection(ROOMS_COLLECTION).document(room_id)

                    room_image_urls = []
                    if available_images:
                        room_images_to_upload = random.sample(available_images, min(3, len(available_images)))
                        for image_path in room_images_to_upload:
                             file_name = os.path.basename(image_path)
                             destination = f"hotels/{hotel_id}/rooms/{room_id}/{uuid.uuid4()}_{file_name}"
                             url = upload_image_and_get_url(image_path, destination)
                             if url:
                                 room_image_urls.append(url)

                    new_room = {
                        "roomId": room_id,
                        "hotelId": hotel_id,
                        "roomType": room_data['roomType'],
                        "roomDescription": room_data['description'],
                        "maxGuests": room_data['maxGuests'],
                        "pricePerNight": room_data['pricePerNight'],
                        "amenities": room_data['amenities'],
                        "images": room_image_urls,
                        "available": True,
                        "createdAt": datetime.now(),
                        "updatedAt": datetime.now()
                    }
                    room_doc_ref.set(new_room)
                    print(f"    - Created room '{room_data['roomType']}' with ID: {room_id}")

        except Exception as e:
            print(f"❌ An error occurred while processing {hotel_data['hotelName']}: {e}")
            # Consider adding rollback logic here if necessary

    print("\n--- ✅ Data Population Complete ---")


def main():
    """Main execution flow."""
    if not initialize_firebase():
        return

    # Confirmation prompt before deleting data
    confirm = input("⚠️ This script will DELETE ALL existing data in collections, auth, and storage. \nAre you sure you want to continue? (yes/no): ")
    if confirm.lower() != 'yes':
        print("Operation cancelled by user.")
        return

    clear_all_data()
    populate_data()


if __name__ == '__main__':
    main()