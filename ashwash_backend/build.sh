#!/usr/bin/env bash
# Exit on error
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py fix_notifications_table || echo "Fix script failed"
python manage.py migrate
python seed_db.py || echo "Seed script failed or skipped"
