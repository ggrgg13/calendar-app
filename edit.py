import psycopg2 # PostgreSQL connection
import datetime # Time handling
import pytz # Timezone handling
class Edit:
    def __init__(self):
        self.conn = psycopg2.connect(
            host="host",
            port="port",
            database="database",
            user="username",
            password="password"
        )

    def create_new_event(self, title: str, description: str, location: str, 
                         start_date: datetime.date, end_date: datetime.date, 
                         start_time: datetime.time, end_time: datetime.time, 
                         frequency: int, interval: int):
        """Handles creation of a new event."""

        try:
            user_timezone = pytz.timezone('America/Los_Angeles')  # Replace with the appropriate user's timezone

            # Create timezone-aware datetime objects
            start_datetime_local = datetime.datetime.combine(start_date, start_time)
            start_datetime_utc = user_timezone.localize(start_datetime_local).astimezone(pytz.utc)

            end_datetime_local = datetime.datetime.combine(end_date, end_time)
            end_datetime_utc = user_timezone.localize(end_datetime_local).astimezone(pytz.utc)

            with self.conn.cursor() as cur:
                # Pass the UTC datetimes to the database function
                cur.execute(
                    """
                    SELECT create_event(
                        %(title)s, %(description)s, %(location)s,
                        %(start_date)s, %(end_date)s,
                        %(start_time)s, %(end_time)s,
                        %(frequency)s, %(interval)s
                    )
                    """, 
                    {
                        'title': title, 'description': description, 'location': location,
                        'start_date': start_datetime_utc.date(), 'end_date': end_datetime_utc.date(),
                        'start_time': start_datetime_utc.time(), 'end_time': end_datetime_utc.time(),
                        'frequency': frequency, 'interval': interval
                    }
                )
                new_event_id = cur.fetchone()[0]  
                self.conn.commit()
                return new_event_id

        except (Exception, psycopg2.Error) as error:
            print("Error creating event:", error)
            return None

    def delete_event(self, event_id: int):
        """Handles event deletion."""
        try:
            with self.conn.cursor() as cur:
                cur.execute("SELECT delete_event(%(event_id)s)", {'event_id': event_id})
                self.conn.commit()

        except (Exception, psycopg2.Error) as error:
            print("Error deleting event:", error)