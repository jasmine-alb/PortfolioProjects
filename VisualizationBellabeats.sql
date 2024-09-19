/* Data analysis of Bellabeats data using MySQL Workbench */

-- Cursory check to make sure everything was uploaded correctly 

SELECT *
FROM `Bellabeats`.`dailyactivity`; 

SELECT *
FROM `Bellabeats`.`hourlycalories`; 

SELECT *
FROM `Bellabeats`.`hourlyintensities`; 

SELECT *
FROM `Bellabeats`.`hourlysteps`; 

SELECT *
FROM `Bellabeats`.`sleepday`; 

SELECT *
FROM `Bellabeats`.`weightloginfo`; 


-- 1. Count Distinct Entries in each table (No Visualization)

SELECT COUNT(DISTINCT Id) AS distinct_ids
FROM `Bellabeats`.`dailyactivity`; -- 33

SELECT COUNT(DISTINCT Id) AS distinct_ids
FROM `Bellabeats`.`hourlycalories`; -- 33

SELECT COUNT(DISTINCT Id) AS distinct_ids
FROM `Bellabeats`.`hourlyintensities`; -- 33

SELECT COUNT(DISTINCT Id) AS distinct_ids
FROM `Bellabeats`.`hourlysteps`; -- 33

SELECT COUNT(DISTINCT Id) AS distinct_ids
FROM `Bellabeats`.`sleepday`; -- 24

SELECT COUNT(DISTINCT Id) AS distinct_ids
FROM `Bellabeats`.`weightloginfo`; -- 8, not sufficient for analysis

/*___________________________________________________________

2. FitBit Usage Activity */ 

-- Tells us how many times each of the users wore/used the FitBit tracker over the course of the month: 
-- Pie Chart

SELECT
	Count(ID) AS NumUsers,
    NumDaysLogged
FROM
	(SELECT 
        ID,
        COUNT(*) AS NumDaysLogged
	FROM `Bellabeats`.`dailyactivity`
	GROUP BY ID) AS LoggedUsageTable
GROUP BY NumDaysLogged
ORDER BY NumDaysLogged DESC

-- Clasifies user by wearable usage (Just a cute visual of the table)
SELECT 
    SUM(CASE 
        WHEN NumDaysLogged BETWEEN 25 AND 31 THEN 1
        ELSE 0
    END) AS Active_Users,
    SUM(CASE 
        WHEN NumDaysLogged BETWEEN 15 AND 24 THEN 1
        ELSE 0
    END) AS Moderate_Users,
    SUM(CASE 
        WHEN NumDaysLogged BETWEEN 0 AND 14 THEN 1
        ELSE 0
    END) AS Light_Users
FROM (
    SELECT 
        ID,
        COUNT(*) AS NumDaysLogged
    FROM `Bellabeats`.`dailyactivity`
    GROUP BY ID
) AS LoggedUsageTable;


/*___________________________________________________________

3. Summarizing and Averaging Data */ 
-- No Visualization 


/* 

SELECT *
FROM `Bellabeats`.`dailyactivity`;

*/


SELECT
    AVG(VeryActiveMinutes),
    AVG(FairlyActiveMinutes),
    AVG(LightlyActiveMinutes),
    AVG(SedentaryMinutes),
    AVG(TotalSteps),
    AVG(Calories)
FROM `Bellabeats`.`dailyactivity`;

SELECT 
	AVG(TotalMinutesAsleep),
    AVG(TotalTimeInBed)
FROM `Bellabeats`.`sleepday`; 

/*___________________________________________________________

4. Comparing Intensity */ 

-- By Day of the Week (Bar Chart)
SELECT
	Weekday,
	AVG(VeryActiveMinutes),
    AVG(FairlyActiveMinutes),
    AVG(LightlyActiveMinutes),
    AVG(SedentaryMinutes)
FROM `Bellabeats`.`dailyactivity`
GROUP BY Weekday
ORDER BY FIELD(Weekday, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
;



-- By Hour of the day throughout the week (Bar/Line Char)

SELECT *
FROM `Bellabeats`.`hourlyintensities`;

-- Looks like the activityhour column was not saved in proper DATETIME format so I corrected it before seperating them out
UPDATE `Bellabeats`.`hourlyintensities`
SET activityhour = STR_TO_DATE(activityhour, '%m/%d/%Y %H:%i:%s');

ALTER TABLE `Bellabeats`.`hourlyintensities`
MODIFY COLUMN activityhour DATETIME;

-- Let's add the new columns 

ALTER TABLE `Bellabeats`.`hourlyintensities`
ADD COLUMN ActivityDate Date; 

ALTER TABLE `Bellabeats`.`hourlyintensities`
ADD COLUMN ActivityTime Time; 

-- Now let's populate these columns with the data from the activityhour column


UPDATE `Bellabeats`.`hourlyintensities`
SET
	ActivityDate = DATE(activityhour),
    ActivityTime = TIME(activityhour); 

-- Now we can find the average intensisty by the hour of the day (Sunday through Saturday)

SELECT
	ActivityTime,
    AVG(AverageIntensity)
FROM `Bellabeats`.`hourlyintensities`
GROUP BY ActivityTime
ORDER BY ActivityTime ASC; 

-- Let's see how this differs on the weekends (Saturday-Sunday)

SELECT
	ActivityTime,
    AVG(AverageIntensity)
FROM `Bellabeats`.`hourlyintensities`
WHERE Weekday IN ('Saturday', 'Sunday') 
GROUP BY ActivityTime
ORDER BY ActivityTime ASC; 


/*___________________________________________________________

5. Steps vs Calories */ 


SELECT *
FROM `Bellabeats`.`hourlysteps`


SELECT *
FROM `Bellabeats`.`hourlycalories`

/* Separating the time and date into separate columns in the hourlysteps table

UPDATE `Bellabeats`.`hourlycalories`
SET activityhour = STR_TO_DATE(activityhour, '%m/%d/%Y %H:%i:%s');

ALTER TABLE `Bellabeats`.`hourlycalories`
ADD COLUMN ActivityDate Date; 

ALTER TABLE `Bellabeats`.`hourlycalories`
ADD COLUMN ActivityTime Time; 

UPDATE `Bellabeats`.`hourlycalories`
SET
	ActivityDate = DATE(activityhour),
    ActivityTime = TIME(activityhour); 
    
 */

-- Comparing Total Seteps vs Calories burned per day  (Scatterplot)                   
SELECT id,
	Activitydate,
    totalsteps,
    calories AS TotalCalories
FROM `Bellabeats`.`dailyactivity`


                    
/*___________________________________________________________

6. Cumulative steps */ 
-- Let's investigate rolling cumulative steps by the hour each day by user 
-- (heatmap or Individual User Progress dashboard)

WITH CumulativeSteps AS (SELECT 
	hs.Id,
	hs.ActivityTime,
	hs.StepTotal,
	hs.ActivityDate,
	SUM(hs.StepTotal) OVER (
		PARTITION BY 
			hs.ActivityDate,
            hs.ID
		ORDER BY id, hs.ActivityTime) AS RollingCumulativeSteps
FROM `Bellabeats`.`hourlysteps` hs
)
SELECT
	Id,
	ActivityDate,
    ActivityTime,
    RollingCumulativeSteps,
	CASE 
        WHEN RollingCumulativeSteps BETWEEN 5000 AND 9999 THEN '5000+ Steps'
        WHEN RollingCumulativeSteps BETWEEN 10000 AND 14999 THEN '10000+ Steps'
        WHEN RollingCumulativeSteps >= 15000 THEN '15000+ Steps'
        ELSE 'Below 5000 Steps'
    END AS StepMilestone
FROM CumulativeSteps
ORDER BY Id, ActivityDate, ActivityTime;


/*___________________________________________________________

7. Sleep Patterns */ 


UPDATE `Bellabeats`.`sleepday`
SET sleepday = STR_TO_DATE(sleepday, '%m/%d/%Y %H:%i:%s');

SELECT *
FROM `Bellabeats`.`sleepday`

-- Compare SleepTime vs Time in bed by Day of the week (Bar Chart) 
SELECT
	Weekday,
	AVG(TotalMinutesAsleep),
    AVG(TotalTimeInBed)
FROM `Bellabeats`.`sleepday`
GROUP BY Weekday
ORDER BY FIELD(Weekday, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
; 


-- Compare `AvgSleepDuration` vs. `AvgSteps` for each day.
SELECT
	sleep.Weekday,
    AVG(sleep.totalminutesasleep) AS AvgSleepDuration,
    AVG(activity.totalsteps) AS AvgSteps
FROM `Bellabeats`.`sleepday` AS sleep
JOIN `Bellabeats`.`dailyactivity` AS activity
	ON sleep.id = activity.id
    AND sleep.sleepday = activity.activitydate
GROUP BY sleep.Weekday
ORDER BY FIELD(sleep.Weekday, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
;


UPDATE `Bellabeats`.`dailyactivity`
SET ActivityDate = STR_TO_DATE(ActivityDate, '%m/%d/%Y %H:%i:%s');

SELECT *
FROM `Bellabeats`.`dailyactivity`



