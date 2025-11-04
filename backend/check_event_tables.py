"""
Quick script to check event-related table structures
"""
from sqlalchemy import inspect
from app.database import engine

inspector = inspect(engine)

print('=== EVENTS TABLE ===')
cols = inspector.get_columns('events')
print('Columns:')
for col in cols:
    print(f'  - {col["name"]}: {col["type"]}')

print('\n=== EVENT_FAVORITES TABLE ===')
try:
    cols = inspector.get_columns('event_favorites')
    print('Columns:')
    for col in cols:
        print(f'  - {col["name"]}: {col["type"]}')
except Exception as e:
    print(f'Error: {e}')

print('\n=== EVENT_PARTICIPATIONS TABLE ===')
cols = inspector.get_columns('event_participations')
print('Columns:')
for col in cols:
    print(f'  - {col["name"]}: {col["type"]}')

print('\n=== ALL TABLES IN DATABASE ===')
all_tables = inspector.get_table_names()
print(f'Total tables: {len(all_tables)}')
for table in all_tables:
    print(f'  - {table}')
