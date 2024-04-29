-- CalenderApp
-- Steven Lin

-- START EDIT OPERATIONS

CREATE OR REPLACE FUNCTION create_event(
    p_title VARCHAR(255),
    p_description TEXT,
    p_location TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_frequency INT,
    p_interval INT
)
RETURNS INT AS $$
DECLARE
    new_event_id INT;
BEGIN
    -- Validate input
    IF p_start_date > p_end_date OR p_start_time > p_end_time THEN
        RAISE EXCEPTION 'Invalid date or time range';
    END IF;

    -- Insert the new event record into the 'Event' table
    INSERT INTO Event (Title, Description, Location, StartDate, EndDate, StartTime, EndTime, Frequency, Interval)
    VALUES (p_title, p_description, p_location, p_start_date, p_end_date, p_start_time, p_end_time, p_frequency, p_interval)
    RETURNING EventID INTO new_event_id;  

    RETURN new_event_id;
END;

CREATE OR REPLACE FUNCTION delete_event(p_event_id INT)
RETURNS void AS $$
BEGIN
    -- Delete the event (cascading delete will handle instances)
    DELETE FROM Event 
    WHERE EventID = p_event_id;
END;

CREATE OR REPLACE FUNCTION edit_event(
    p_event_id INT,
    p_title VARCHAR(255),
    p_description TEXT,
    p_location TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_frequency INT,
    p_interval INT
)
RETURNS void AS $$
BEGIN
    -- Input validation (add more checks as needed)
    IF p_start_date > p_end_date OR p_start_time > p_end_time THEN
        RAISE EXCEPTION 'Invalid date or time range';
    END IF;

    -- Update the event record in the 'Event' table
    UPDATE Event
    SET 
        Title = p_title,
        Description = p_description,
        Location = p_location,
        StartDate = p_start_date,
        EndDate = p_end_date,
        StartTime = p_start_time,
        EndTime = p_end_time,
        Frequency = p_frequency,
        Interval = p_interval
    WHERE EventID = p_event_id;

    -- Optional: Handle the update of existing instances and generation of new ones
    -- You might want to call functions like 'update_display' here, 
    -- depending on how your UI and calendar logic is designed.
END;

-- END EDIT OPERATIONS

-- START UPDATE DISPLAY

-- Dynamically create and delete events based on what time period is displayed
-- Is wrapped in a transaction for safty
CREATE OR REPLACE FUNCTION update_display(display_start_date DATE, display_end_date DATE)
RETURNS void AS $$
BEGIN
    BEGIN;
        -- Delete all entries from EventInstance
        DELETE FROM EventInstance;

        -- Call the function to create new event instances within the specified range
        PERFORM create_event_instances(display_start_date, display_end_date);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- In case of an error during deletion or instance creation, roll back the transaction
        ROLLBACK;
        RAISE;  -- Reraise the caught exception for further handling or logging
END;

-- END UPDATE DISPLAY

-- START EVENT INSTANCE MANAGEMENT

-- Insert a single event instance given event, rules
CREATE OR REPLACE FUNCTION insert_event_instance(
    p_event_id INT,
    p_rule_id INT,
    p_start_datetime TIMESTAMP,
    p_end_datetime TIMESTAMP
)
RETURNS void AS $$
BEGIN
    -- Insert the provided values into the EventInstance table
    INSERT INTO EventInstance (EventID, RuleID, StartDateTime, EndDateTime)
    VALUES (p_event_id, p_rule_id, p_start_datetime, p_end_datetime);
END;

-- Create all event instances in the displayed timeframe
CREATE OR REPLACE FUNCTION create_event_instances(display_start_date DATE, display_end_date DATE)
RETURNS void AS $$
DECLARE
    event RECORD;
    current_date DATE;
    week_of_month INT;
    day_of_week INT;
    month_num INT;
    day_num INT;
    target_date DATE;
    start_datetime TIMESTAMP;
    end_datetime TIMESTAMP;
BEGIN
    FOR event IN SELECT * FROM Event LOOP -- Removed range check on dates 

        current_date := event.StartDate; -- No initialization with GREATEST()

        WHILE current_date <= display_end_date LOOP -- Removed COALESCE() for speed 
            start_datetime := current_date + event.StartTime::time;
            end_datetime := current_date + event.EndTime::time;

            CASE event.Frequency
                WHEN 0 THEN
                    PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                    EXIT; 

                WHEN 1 THEN
                    PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                    current_date := current_date + INTERVAL '1 day';

                WHEN 2 THEN
                    PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                    current_date := current_date + INTERVAL '1 week';

                WHEN 3 THEN
                    PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                    current_date := current_date + INTERVAL '1 month';

                WHEN 4 THEN
                    PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                    current_date := current_date + INTERVAL '1 year';

                -- Case 5 to 7 has their own while loops to improve performance. When the inner while loop resolve, the outer while loops should immediately resolve as well

                WHEN 5 THEN
                    week_of_month := (event.Interval / 10) :: INT;
                    day_of_week := event.Interval % 10;
                    current_date := DATE_TRUNC('month', current_date) + (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day';
                    WHILE current_date <= display_end_date AND current_date >= DATE_TRUNC('month', current_date) AND EXTRACT(DAY FROM current_date) <= 28 LOOP 
                        PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                        current_date := DATE_TRUNC('month', current_date + INTERVAL '1 month') + (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day';
                    END LOOP;

                WHEN 6 THEN
                    month_num := (event.Interval / 100);
                    day_num := (event.Interval % 100);

                    -- Optimization:  Move the adjustment outside the main loop
                    IF EXTRACT(DAY FROM current_date) != day_num THEN
                        current_date := MAKE_DATE(EXTRACT(YEAR FROM current_date)::INT, month_num, day_num);
                    END IF;

                    WHILE current_date <= display_end_date LOOP -- Main loop
                        start_datetime := current_date + event.StartTime::time;
                        end_datetime := current_date + event.EndTime::time;
                        PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);
                        current_date := MAKE_DATE(EXTRACT(YEAR FROM current_date)::INT + 1, month_num, day_num);
                    END LOOP;

                WHEN 7 THEN
                    month_num := (event.Interval / 100);
                    week_of_month := (event.Interval % 100) / 10;
                    day_of_week := event.Interval % 10;

                    current_date := DATE_TRUNC('month', current_date) + (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day'; 

                    WHILE current_date <= display_end_date LOOP 
                        start_datetime := current_date + event.StartTime::time;
                        end_datetime := current_date + event.EndTime::time;
                        PERFORM insert_event_instance(event.EventID, event.EventID, start_datetime, end_datetime);

                        current_date := MAKE_DATE(EXTRACT(YEAR FROM current_date)::INT + 1, month_num, 1) +
                                    (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day'; 
                    END LOOP;
            END CASE;
        END LOOP;
    END LOOP;
END;

-- END EVENT INSTANCE MANAGEMENT
$$ LANGUAGE plpgsql;