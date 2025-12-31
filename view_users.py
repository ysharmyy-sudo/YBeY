from backend.database import SessionLocal
from backend.models import User

def view_users():
    db = SessionLocal()
    try:
        users = db.query(User).all()
        if not users:
            print("\nNo users found in the database.")
            return

        print("\n" + "="*80)
        print(f"{'ID':<5} {'Username':<20} {'Email':<30} {'Created At'}")
        print("-" * 80)
        for user in users:
            created_at = user.created_at.strftime("%Y-%m-%d %H:%M:%S") if user.created_at else "N/A"
            print(f"{user.id:<5} {user.username:<20} {user.email:<30} {created_at}")
        print("="*80 + "\n")
    finally:
        db.close()

if __name__ == "__main__":
    view_users()
