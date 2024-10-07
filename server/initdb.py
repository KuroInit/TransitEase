import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate("server/TransitEase.json")
firebase_admin.initialize_app(cred)
