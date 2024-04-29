-- CalenderApp
-- Steven Lin

-- Uses PostgreSQL format
-- Assume server is always in UTC time
CREATE TABLE Event (
    EventID SERIAL PRIMARY KEY,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE
    Frequency INT NOT NULL,
    Interval INT NOT NULL DEFAULT 0,
    Title VARCHAR(255) NOT NULL,
    Description TEXT,
    Location TEXT,
);

CREATE TABLE EventInstance (
    EventInstanceID SERIAL PRIMARY KEY,
    EventID INT NOT NULL,
    StartDateTime TIMESTAMP NOT NULL,
    EndDateTime TIMESTAMP NOT NULL,
    FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (RuleID) REFERENCES RecurrenceRule(RuleID) ON DELETE CASCADE ON UPDATE CASCADE
);
/*
Events contain rules that are used to create EventInstances.
Frequency determines basic recurrence rules. It can be:
0: not repeating
1: every day
2: every week
3: every month
4: every year
5: Xth week of every month
6: Xth day of Xth month every year
7: Xth week of Xth month every year

Interval determines detailed recurrence rules. Its rulesets change depending on the frequency:
0: not applicable
Every week: 1~7 for weekdays
Every month: 1~31 for day of the month
Every year: 1~356 for day in the year
Xth week of every month: 2 digits, where the first digit is the week number (1-5) and the second
digit is the weekday (1=Monday, ... 7=Sunday)
    For example: 23 means the 3rd Wednesday of the month
Xth day of Xth month every year: 4 digits, where the first two digits are the month (01-12) and
the last two digits are the day (01-31)
    For example: 0305 means March 5th
Xth week of Xth month every year: 4 digits, where the first two digits are the month (01-12), the
third digit is the week of the month (1-5), and the last digit is the weekday (1=Monday, ... 7=Sunday)
    For example: 0825 means the 5th Friday of August
*/