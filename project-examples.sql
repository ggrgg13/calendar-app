/*
CalenderApp
Steven Lin
*/
/*
Most of it are functions already written in project-queries, rearranged for clarity
*/
-- Insert a simple event
SELECT create_event('Dummy', 'Dumdum', 'dummm', 
                    '2024-03-05', NULL, '12:00:00', '16:00:00', 0, 0); 

-- Test complex insert
SELECT create_event('March 7th!', 'This is a video game reference', 'Astral Express', 
                    '2024-03-07', NULL, '11:00:00', '16:00:00', 6, 0307); 
-- Note that 0307 is stored as 307, but that does not affect the correctness of int parsing.

-- Confirm the event exists
SELECT * from Events;

-- Update display. This deletes everything in EventInstance, then create new EventInstances within the provided timeframe

SELECT update_display('2024-01-06'::DATE, '2025-06-08'::DATE);

-- View EventInstances after updating display
-- This would be used in a GUI to render events.
-- Since EventInstances are created by the update_display date, there is no need to filter it at all
SELECT * FROM EventInstance;

-- When clicking on an event instance in a GUI, this would be run to retrieve all the information needed
-- for rendering the event details.
SELECT ei.*, e.*
FROM EventInstance ei
JOIN Events e ON ei.EventID = e.EventID
WHERE ei.EventInstanceID = <specific_event_instance_id>;