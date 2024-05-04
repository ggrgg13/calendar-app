import psycopg2
import datetime
import pytz
import edit
import os
host = os.getenv("HOST")
port = os.getenv("PORT")
password = os.getenv("PASSWORD")
class GUI:
    def __init__(self):
        self.conn = psycopg2.connect(
            host="host",
            port="port",
            database="postgres",
            user="postgres",
            password=password
        )

    def update_display(self, display_start: datetime.date, display_end: datetime.date):
        """Fetches events for display and converts them to the user's timezone."""
        try:
            user_timezone = pytz.timezone('America/Los_Angeles')  # Replace with the appropriate user's timezone

            with self.conn.cursor() as cur:
                # Pass UTC dates directly to update_display
                cur.execute("SELECT update_display(%(start)s, %(end)s)", 
                    {'start': display_start, 'end': display_end})
                self.conn.commit()

                # Fetch results (assuming update_display returns event data)
                results = cur.fetchall()  

                # Convert fetched UTC datetimes to the user's timezone
                events_for_display = []
                for row in results:
                    event_start_utc = row['event_start_datetime']
                    event_end_utc = row['event_end_datetime']  # Retrieve the end datetime

                    event_start_local = event_start_utc.astimezone(user_timezone)
                    event_end_local = event_end_utc.astimezone(user_timezone)  # Convert end datetime

                    # Create a display-friendly event 
                    event_for_display = {
                        'title': row['title'],
                        # ... other attributes ... 
                        'start_datetime': event_start_local,
                        'end_datetime': event_end_local
                    }
                    events_for_display.append(event_for_display)

                return events_for_display # returns 

        except (Exception, psycopg2.Error) as error:
            print("Error updating display:", error)
            return None  # Or an empty list to indicate an error to the GUI 