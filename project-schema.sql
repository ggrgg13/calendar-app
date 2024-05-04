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
    -- Validate time selection
    IF p_start_date > p_end_date OR p_start_time > p_end_time THEN
        RAISE EXCEPTION 'Invalid date or time range';
    END IF;

    -- Insert the new event record into the 'Events' table
    INSERT INTO Events (Title, Description, Location, StartDate, EndDate, StartTime, EndTime, Frequency, Interval)
    VALUES (p_title, p_description, p_location, p_start_date, p_end_date, p_start_time, p_end_time, p_frequency, p_interval)
    RETURNING EventID INTO new_event_id;  

    RETURN new_event_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_event(p_event_id INT)
RETURNS void AS $$
BEGIN
    -- Delete the event (cascading delete will handle instances)
    DELETE FROM Events
    WHERE EventID = p_event_id;
END;
$$ LANGUAGE plpgsql;

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
END;
$$ LANGUAGE plpgsql;

-- END EDIT OPERATIONS

-- START UPDATE DISPLAY

-- Dynamically create and delete events based on what time period is displayed
CREATE OR REPLACE FUNCTION update_display(display_start_date DATE, display_end_date DATE)
RETURNS void AS $$
BEGIN
    RAISE NOTICE 'begin update display';
    -- Delete all entries from EventInstance
    DELETE FROM EventInstance;
    RAISE NOTICE 'deleted all instances';
    -- Call the function to create new event instances within the specified range
    RAISE NOTICE 'creating instances';
    PERFORM create_event_instances(display_start_date, display_end_date);
    RAISE NOTICE 'done creating instances';
END;
$$ LANGUAGE plpgsql;

-- END UPDATE DISPLAY

-- START EVENT INSTANCE MANAGEMENT

-- Insert a single event instance given event, rules
CREATE OR REPLACE FUNCTION insert_event_instance(
    p_event_id INT,
    p_start_datetime TIMESTAMP WITHOUT TIME ZONE,
    p_end_datetime TIMESTAMP WITHOUT TIME ZONE
)
RETURNS void AS $$
BEGIN
    -- Insert the provided values into the EventInstance table
    INSERT INTO EventInstance (EventID, StartDateTime, EndDateTime)
    VALUES (p_event_id, p_start_datetime, p_end_datetime);
END;
$$ LANGUAGE plpgsql;

-- Create all event instances in the displayed timeframe
CREATE OR REPLACE FUNCTION create_event_instances(display_start_date DATE, display_end_date DATE)
RETURNS void AS $$
DECLARE
    event_row RECORD;
    cursor_date DATE;
    week_of_month INT;
    day_of_week INT;
    month_num INT;
    day_num INT;
    target_date DATE;
    start_datetime TIMESTAMP;
    end_datetime TIMESTAMP;
BEGIN
    RAISE NOTICE 'begin instance creation';
    RAISE NOTICE 'Display Start Date: %, Display End Date: %', display_start_date, display_end_date;
    RAISE NOTICE 'begin looping over all event';
    FOR event_row IN SELECT * FROM Events
    LOOP
        RAISE NOTICE 'success?';
    END LOOP;
    
    FOR event_row IN SELECT * FROM Events
        WHERE Events.StartDate >= display_start_date AND 
            (Events.EndDate IS NULL OR Events.EndDate <= display_end_date)
    LOOP
        RAISE NOTICE 'parsing event %', event_row.EventID;
        cursor_date = event_row.StartDate;

        WHILE cursor_date <= display_end_date LOOP
            start_datetime = cursor_date + event_row.StartTime::time;
            end_datetime = cursor_date + event_row.EndTime::time;

            CASE event_row.Frequency
                WHEN 0 THEN
                    RAISE NOTICE 'Inserting event instance for frequency 0';
                    PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                    EXIT; 
                    RAISE NOTICE 'Event instance inserted for frequency 0';

                WHEN 1 THEN
                    RAISE NOTICE 'Inserting event instance for frequency 1';
                    PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                    cursor_date = cursor_date + INTERVAL '1 day';
                    RAISE NOTICE 'Event instance inserted for frequency 1';

                WHEN 2 THEN
                    RAISE NOTICE 'Inserting event instance for frequency 2';
                    PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                    cursor_date = cursor_date + INTERVAL '1 week';
                    RAISE NOTICE 'Event instance inserted for frequency 2';

                WHEN 3 THEN
                    RAISE NOTICE 'Inserting event instance for frequency 3';
                    PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                    cursor_date= cursor_date + INTERVAL '1 month';
                    RAISE NOTICE 'Event instance inserted for frequency 3';

                WHEN 4 THEN
                    RAISE NOTICE 'Inserting event instance for frequency 4';
                    PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                    cursor_date = cursor_date + INTERVAL '1 year';
                    RAISE NOTICE 'Event instance inserted for frequency 4';

                -- Case 5 to 7 has their own while loops to improve performance. When the inner while loop resolve, the outer while loops should immediately resolve as well

                WHEN 5 THEN
                    RAISE NOTICE 'Inserting event instances for frequency 5';
                    week_of_month = (event_row.Interval / 10) :: INT;
                    day_of_week = event_row.Interval % 10;
                    cursor_date = DATE_TRUNC('month', cursor_date) + (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day';
                    WHILE cursor_date <= display_end_date AND cursor_date >= DATE_TRUNC('month', cursor_date) AND EXTRACT(DAY FROM cursor_date) <= 28 LOOP 
                        PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                        cursor_date = DATE_TRUNC('month', cursor_date + INTERVAL '1 month') + (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day';
                    END LOOP;
                    RAISE NOTICE 'Event instances inserted for frequency 5';

                WHEN 6 THEN
                    RAISE NOTICE 'Inserting event instances for frequency 6';
                    month_num = (event_row.Interval / 100);
                    day_num = (event_row.Interval % 100);

                    -- Optimization:  Move the adjustment outside the main loop
                    IF EXTRACT(DAY FROM cursor_date) != day_num THEN
                        cursor_date = MAKE_DATE(EXTRACT(YEAR FROM cursor_date)::INT, month_num, day_num);
                    END IF;

                    WHILE cursor_date <= display_end_date LOOP -- Main loop
                        start_datetime = cursor_date + event_row.StartTime::time;
                        end_datetime = cursor_date + event_row.EndTime::time;
                        PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);
                        cursor_date = MAKE_DATE(EXTRACT(YEAR FROM cursor_date)::INT + 1, month_num, day_num);
                    END LOOP;
                    RAISE NOTICE 'Event instances inserted for frequency 6';

                WHEN 7 THEN
                    RAISE NOTICE 'Inserting event instances for frequency 7';
                    month_num = (event_row.Interval / 100);
                    week_of_month = (event_row.Interval % 100) / 10;
                    day_of_week = event_row.Interval % 10;

                    cursor_date = DATE_TRUNC('month', cursor_date) + (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day'; 

                    WHILE cursor_date <= display_end_date LOOP 
                        start_datetime = cursor_date + event_row.StartTime::time;
                        end_datetime = cursor_date + event_row.EndTime::time;
                        PERFORM insert_event_instance(event_row.EventID, start_datetime, end_datetime);

                        cursor_date = MAKE_DATE(EXTRACT(YEAR FROM cursor_date)::INT + 1, month_num, 1) +
                                    (week_of_month - 1) * INTERVAL '1 week' + (day_of_week - 1) * INTERVAL '1 day'; 
                    END LOOP;
                    RAISE NOTICE 'Event instances inserted for frequency 7';
                RAISE NOTICE 'No cases used';
            END CASE;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- END EVENT INSTANCE MANAGEMENT
