from sqlalchemy import create_engine, inspect
from backend.models import User

SQLALCHEMY_DATABASE_URL = "sqlite:///./ybey.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL)

inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"Tables found: {tables}")

for table in tables:
    print(f"\nColumns in {table}:")
    for column in inspector.get_columns(table):
        print(f"  - {column['name']} ({column['type']})")
