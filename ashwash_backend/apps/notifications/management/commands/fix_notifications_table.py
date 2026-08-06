"""
Fix broken notifications table by dropping and recreating it.
This command handles the case where the table exists but is missing columns
because migrations were partially applied or the table was created manually.
"""
from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = 'Fix broken notifications tables by dropping them and letting migrate recreate them properly'

    def handle(self, *args, **options):
        tables_to_fix = [
            'notifications_notification',
            'notifications_fcmdevice',
        ]

        with connection.cursor() as cursor:
            # Check which tables exist
            existing_tables = connection.introspection.table_names()
            self.stdout.write(f"Existing tables: {len(existing_tables)} total")

            for table_name in tables_to_fix:
                if table_name in existing_tables:
                    self.stdout.write(self.style.WARNING(f"Dropping broken table: {table_name}"))
                    try:
                        cursor.execute(f'DROP TABLE IF EXISTS "{table_name}" CASCADE')
                        self.stdout.write(self.style.SUCCESS(f"Dropped table: {table_name}"))
                    except Exception as e:
                        # Try without CASCADE for MySQL
                        try:
                            cursor.execute(f'SET FOREIGN_KEY_CHECKS = 0')
                            cursor.execute(f'DROP TABLE IF EXISTS `{table_name}`')
                            cursor.execute(f'SET FOREIGN_KEY_CHECKS = 1')
                            self.stdout.write(self.style.SUCCESS(f"Dropped table (MySQL): {table_name}"))
                        except Exception as e2:
                            self.stdout.write(self.style.ERROR(f"Failed to drop {table_name}: {e2}"))
                else:
                    self.stdout.write(f"Table {table_name} does not exist (will be created by migrate)")

            # Also clear the migration record so Django knows to re-run them
            try:
                cursor.execute("DELETE FROM django_migrations WHERE app = 'notifications'")
                self.stdout.write(self.style.SUCCESS("Cleared notifications migration history"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Failed to clear migration history: {e}"))

        self.stdout.write(self.style.SUCCESS("Done! Now run 'python manage.py migrate' to recreate tables properly."))
