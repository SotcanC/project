USE msdb
Go
set transaction isolation level read uncommitted

; WITH RADHE AS (

SELECT 
    [SERVER NAME] = @@servername 

    ,J.Name AS 'Job Name', 

    'Job Enabled' = CASE J.Enabled
        WHEN 1 THEN 'Yes'
        WHEN 0 THEN 'No'
    END,

    [Schedule Enabled] = CASE SS.Enabled
        WHEN 1 THEN 'Yes'
        WHEN 0 THEN 'No'
    END,

    [Schedule Name] = COALESCE(SS.NAME,'No Name'),

    [Next Time it Will Run] = sja.next_scheduled_run_date,

    'Start Date' = CASE active_start_date
        WHEN 0 THEN null
        ELSE
        substring(convert(varchar(15),active_start_date),1,4) + '/' + 
        substring(convert(varchar(15),active_start_date),5,2) + '/' + 
        substring(convert(varchar(15),active_start_date),7,2)
    END,
    'Start Time' = CASE len(active_start_time)
        WHEN 1 THEN cast('00:00:0' + right(active_start_time,2) as char(8))
        WHEN 2 THEN cast('00:00:' + right(active_start_time,2) as char(8))
        WHEN 3 THEN cast('00:0' 
                + Left(right(active_start_time,3),1)  
                +':' + right(active_start_time,2) as char (8))
        WHEN 4 THEN cast('00:' 
                + Left(right(active_start_time,4),2)  
                +':' + right(active_start_time,2) as char (8))
        WHEN 5 THEN cast('0' 
                + Left(right(active_start_time,5),1) 
                +':' + Left(right(active_start_time,4),2)  
                +':' + right(active_start_time,2) as char (8))
        WHEN 6 THEN cast(Left(right(active_start_time,6),2) 
                +':' + Left(right(active_start_time,4),2)  
                +':' + right(active_start_time,2) as char (8))
    END,
--  active_start_time as 'Start Time',
    CASE len(run_duration)
        WHEN 1 THEN cast('00:00:0'
                + cast(run_duration as char) as char (8))
        WHEN 2 THEN cast('00:00:'
                + cast(run_duration as char) as char (8))
        WHEN 3 THEN cast('00:0' 
                + Left(right(run_duration,3),1)  
                +':' + right(run_duration,2) as char (8))
        WHEN 4 THEN cast('00:' 
                + Left(right(run_duration,4),2)  
                +':' + right(run_duration,2) as char (8))
        WHEN 5 THEN cast('0' 
                + Left(right(run_duration,5),1) 
                +':' + Left(right(run_duration,4),2)  
                +':' + right(run_duration,2) as char (8))
        WHEN 6 THEN cast(Left(right(run_duration,6),2) 
                +':' + Left(right(run_duration,4),2)  
                +':' + right(run_duration,2) as char (8))
    END as 'Max Duration',

    CASE(SS.freq_subday_interval)
        WHEN 0 THEN 'Once'
        ELSE cast('Every ' 
                + right(SS.freq_subday_interval,2) 
                + ' '
                +     CASE(SS.freq_subday_type)
                            WHEN 1 THEN 'Once'
                            WHEN 4 THEN 'Minutes'
                            WHEN 8 THEN 'Hours'
                        END as char(16))
    END as 'Subday Frequency',

'Frequency'    = CASE(ss.freq_type)
                  WHEN 1  THEN 'Once'
                  WHEN 4  THEN 'Daily'
                  WHEN 8  THEN 
                    (case when (ss.freq_recurrence_factor > 1) 
                        then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
                  WHEN 16 THEN 
                    (case when (ss.freq_recurrence_factor > 1) 
                    then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' else 'Monthly' end)
                  WHEN 32 THEN 'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' -- RELATIVE
                  WHEN 64 THEN 'SQL Startup'
                  WHEN 128 THEN 'SQL Idle'
                  ELSE '??'
                END,

'Interval'    = CASE
                 WHEN (freq_type = 1)                       then 'One time only'
                 WHEN (freq_type = 4 and freq_interval = 1) then 'Every Day'
                 WHEN (freq_type = 4 and freq_interval > 1) then 'Every ' + convert(varchar(10),freq_interval) + ' Days'
                 WHEN (freq_type = 8) then (select 'Weekly Schedule' = D1+ D2+D3+D4+D5+D6+D7 
                       from (select ss.schedule_id,
                     freq_interval, 
                     'D1' = CASE WHEN (freq_interval & 1  <> 0) then 'Sun ' ELSE '' END,
                     'D2' = CASE WHEN (freq_interval & 2  <> 0) then 'Mon '  ELSE '' END,
                     'D3' = CASE WHEN (freq_interval & 4  <> 0) then 'Tue '  ELSE '' END,
                     'D4' = CASE WHEN (freq_interval & 8  <> 0) then 'Wed '  ELSE '' END,
                    'D5' = CASE WHEN (freq_interval & 16 <> 0) then 'Thu '  ELSE '' END,
                     'D6' = CASE WHEN (freq_interval & 32 <> 0) then 'Fri '  ELSE '' END,
                     'D7' = CASE WHEN (freq_interval & 64 <> 0) then 'Sat '  ELSE '' END
                                 from msdb..sysschedules ss
                                where freq_type = 8
                           ) as F
                       where schedule_id = sj.schedule_id
                                            )
                 WHEN (freq_type = 16) then 'Day ' + convert(varchar(2),freq_interval) 
                 WHEN (freq_type = 32) then (select freq_rel + WDAY 
                    from (select ss.schedule_id,
                                 'freq_rel' = CASE(freq_relative_interval)
                                                WHEN 1 then 'First'
                                                WHEN 2 then 'Second'
                                                WHEN 4 then 'Third'
                                                WHEN 8 then 'Fourth'
                                                WHEN 16 then 'Last'
                                                ELSE '??'
                                              END,
                                'WDAY'     = CASE (freq_interval)
                                                WHEN 1  then ' Sun'
                                                WHEN 2  then ' Mon'
                                                WHEN 3  then ' Tue'
                                                WHEN 4  then ' Wed'
                                                WHEN 5  then ' Thu'
                                                WHEN 6  then ' Fri'
                                                WHEN 7  then ' Sat'
                                                WHEN 8  then ' Day'
                                                WHEN 9  then ' Weekday'
                                                WHEN 10 then ' Weekend'
                                                ELSE '??'
                                              END
                            from msdb..sysschedules ss
                            where ss.freq_type = 32
                         ) as WS 
                   where WS.schedule_id =ss.schedule_id
                   ) 
               END,

'Time' = CASE (freq_subday_type)
                WHEN 1 then   left(stuff((stuff((replicate('0', 6 - len(Active_Start_Time)))+ convert(varchar(6),Active_Start_Time),3,0,':')),6,0,':'),8)
                WHEN 2 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' seconds'
                WHEN 4 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' minutes'
                WHEN 8 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' hours'
                ELSE '??'
              END,

'Next Run Time' = (SELECT TOP 1 CASE MIN(SJ.next_run_date)
                              WHEN 0 THEN cast('n/a' as char(10))
                              ELSE convert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
                         END               
                     FROM  dbo.sysjobschedules SJ
                     WHERE J.job_id = SJ.job_id
                       AND SJ.next_run_date >= ss.active_start_date -- mm 13-june-2014
                     GROUP BY SJ.next_run_date,SJ.next_run_time
                     ORDER BY SJ.next_run_date,SJ.next_run_time
                 ),

    [Last Time It Run]=R1.[Last Time It Run],

   [Last Run Status]=COALESCE(CASE R1.run_status 
                                    WHEN 0 THEN 'Failed'
                                    WHEN 1 THEN 'Success'
                                    WHEN 2 THEN 'Retry'
                                    WHEN 3 THEN 'Canceled'
                                    WHEN 4 THEN 'In progress'
                               END, 'No history') --30 chars

   --select ss.*

FROM dbo.sysjobs J
OUTER APPLY (SELECT TOP 1 * FROM 
             msdb.dbo.sysjobactivity SJA
             WHERE  J.job_id = SJA.job_id
             ORDER BY START_EXECUTION_DATE DESC) sja

LEFT OUTER JOIN dbo.sysjobschedules SJ
             ON J.job_id = SJ.job_id

LEFT OUTER JOIN  dbo.sysschedules SS 
             ON  SS.schedule_id = SJ.schedule_id 

LEFT OUTER JOIN (SELECT job_id

                       ,run_duration=max(run_duration)
                       ,run_status 
                       ,[Last Time It Run]=MAX(CAST(
                        STUFF(STUFF(CAST(jh.run_date as varchar),7,0,'-'),5,0,'-') + ' ' + 
                        STUFF(STUFF(REPLACE(STR(jh.run_time,6,0),' ','0'),5,0,':'),3,0,':') as datetime))  

                   FROM dbo.sysjobhistory JH 
               GROUP BY job_id,run_status ) R1

               ON J.job_id = R1.job_id
--ORDER BY [Start Date],[Start Time]

)
SELECT * 
  FROM RADHE R

-- the lines below are for the work related to this question only

  --WHERE [Schedule Enabled] = 'Yes' 
  --  AND R.[JOB NAME] IN 
  --( 'WebFeed UKProductOffer Offers'
  -- ,'WebFeed USProductOffer Offers'
  -- ,'WebFeed DEProductOffer Offers'
  -- ,'WebFeed ATProductOffer Offers'
  -- ,'WebFeed FRProductOffer Offers'
  -- ,'WebFeed EUProductOffer Offers'
  -- ,'WebFeed AUProductOffer Offers')
  -- and [schedule name] like '%ad hoc%'