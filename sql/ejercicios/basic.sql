-- 1.-How can you retrieve all the information from the cd.facilities table?
SELECT * FROM cd.facilities;

-- 2.-You want to print out a list of all of the facilities and their cost to members. 
--How would you retrieve a list of only facility names and costs?
SELECT name, membercost FROM cd.facilities;

-- 3.- How can you produce a list of facilities that charge a fee to members?
SELECT facid, name, membercost, guestcost, initialoutlay, monthlymaintenance
FROM cd.facilities WHERE membercost > 0;

-- 4.- How can you produce a list of facilities that charge a fee to 
-- members, and that fee is less than 1/50th of the monthly maintenance cost? 
-- Return the facid, facility name, member cost, and monthly maintenance of the facilities in question.
SELECT facid, name, membercost, monthlymaintenance
FROM cd.facilities WHERE membercost > 0 AND membercost < (monthlymaintenance * 0.02);

--5.- How can you produce a list of all facilities with the word 'Tennis' in their name?
SELECT *
FROM cd.facilities WHERE name LIKE '%Tennis%';

-- 6.- How can you retrieve the details of facilities with ID 1 and 5? Try to do it without using the OR operator.
SELECT *
FROM cd.facilities
WHERE facid IN (1,5);

-- 7.-How can you produce a list of facilities, with each labelled as 'cheap' or 'expensive'
-- depending on if their monthly maintenance cost is more than $100? Return the name and monthly maintenance of the facilities in question.
SELECT name, 
	CASE
		WHEN monthlymaintenance > 100 THEN 'expensive'
		ELSE 'cheap'
	END AS cost
FROM cd.facilities 

-- 8.-How can you produce a list of members who joined after the start of September 2012?
-- Return the memid, surname, firstname, and joindate of the members in question.
SELECT memid, surname, firstname, joindate
FROM cd.members
WHERE joindate >= '2012-09-01' AND joindate <= '2012-09-30';

-- 9.- How can you produce an ordered list of the first 10 surnames in the members table? 
--The list must not contain duplicates.
SELECT DISTINCT surname
FROM cd.members
ORDER BY surname ASC
LIMIT 10;

-- 10.-You, for some reason, want a combined list of all surnames and all facility names. 
--Yes, this is a contrived example :-). Produce that list!
SELECT surname FROM cd.members 
UNION
SELECT name FROM cd.facilities;

-- 11.-You'd like to get the signup date of your last member. How can you retrieve this information?
SELECT joindate AS latest
FROM cd.members
ORDER BY joindate DESC
LIMIT 1;

-- 12.- You'd like to get the first and last name of the last member(s) who signed up - not just the date. How can you do that?
SELECT firstname, surname, joindate
FROM cd.members
ORDER BY joindate DESC
LIMIT 1;

--agregged:
-- For our first foray into aggregates, we're going to stick to something simple.
-- We want to know how many facilities exist - simply produce a total count.
SELECT COUNT(name) AS count
FROM cd.facilities;

--Produce a count of the number of facilities that have a cost to guests of 10 or more.
SELECT COUNT(*) AS count
FROM cd.facilities
WHERE guestcost > 10;

--Produce a count of the number of recommendations each member has made. Order by member ID.
--cuantas veces aparece el id de un miembro en recommendedby
SELECT recommendedby, COUNT(memid) as count
FROM cd.members
WHERE recommendedby IS NOT NULL
GROUP BY recommendedby
ORDER BY recommendedby;

--Produce a list of the total number of slots booked per facility. For now, just produce an output table consisting of facility id and slots, sorted by facility id.
SELECT facid, SUM (slots) AS Totalslots
FROM cd.bookings
GROUP BY facid
ORDER BY facid ASC;

--Produce a list of the total number of slots booked per facility in the month of September 2012. 
--Produce an output table consisting of facility id and slots, sorted by the number of slots.
SELECT facid, SUM (slots) AS Totalslots
FROM cd.bookings
WHERE starttime >= '2012-09-01' AND starttime < '2012-10-01'
GROUP BY facid
ORDER BY Totalslots ASC;

--Produce a list of the total number of slots booked per facility per month in the year of 2012.
--Produce an output table consisting of facility id and slots, sorted by the id and month.
SELECT 
    facid, 
    EXTRACT(MONTH FROM starttime) AS month, 
    SUM(slots) AS "Total Slots"
FROM cd.bookings
WHERE starttime >= '2012-01-01' AND starttime < '2013-01-01'
GROUP BY facid, month
ORDER BY facid, month;

--Find the total number of members (including guests) who have made at least one booking.
SELECT COUNT(DISTINCT memid) 
FROM cd.bookings;

--Produce a list of facilities with more than 1000 slots booked. 
--Produce an output table consisting of facility id and slots, sorted by facility id.
SELECT facid, SUM(slots) AS TotalSlots
FROM cd.bookings
GROUP BY facid
HAVING SUM(slots)  > 1000
ORDER BY facid;

--Produce a list of facilities along with their total revenue. The output table should consist of facility name and revenue, sorted by revenue. 
--Remember that there's a different cost for guests and members!
SELECT
    facs.name,
    SUM(
        slots *
        CASE
            WHEN memid = 0 THEN facs.guestcost
            ELSE facs.membercost
        END
    ) AS Revenue
FROM cd.bookings
INNER JOIN cd.facilities AS facs
    ON cd.bookings.facid = facs.facid
GROUP BY facs.name
ORDER BY Revenue;

--Produce a list of facilities with a total revenue less than 1000. 
--Produce an output table consisting of facility name and revenue, sorted by revenue. Remember that there's a different cost for guests and members!
select facs.name, sum(case 
		when memid = 0 then slots * facs.guestcost
		else slots * membercost
	end) as revenue
	from cd.bookings bks
	inner join cd.facilities facs
		on bks.facid = facs.facid
	group by facs.name
	having sum(case 
		when memid = 0 then slots * facs.guestcost
		else slots * membercost
	end) < 1000
order by revenue;

--Output the facility id that has the highest number of slots booked. For bonus points, 
--try a version without a LIMIT clause. This version will probably look messy!
SELECT facid, SUM(slots) AS totalslots
FROM cd.bookings
GROUP BY facid
HAVING SUM(slots) = (
    SELECT MAX(totalslots) 
    FROM (
        SELECT SUM(slots) AS totalslots
        FROM cd.bookings
        GROUP BY facid
    ) AS subq
);