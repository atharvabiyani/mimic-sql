--query 1
SELECT 
    adm.subject_id,
    adm.hadm_id,
    -- standardize diagnosis to uppercase to catch all variations
    UPPER(adm.diagnosis) AS diag_clean,
    adm.admission_type,
    -- get the year from the admission timestamp
    EXTRACT(YEAR FROM adm.admittime) AS admit_year,
    trx.curr_careunit AS initial_icu
FROM ADMISSIONS adm
JOIN TRANSFERS trx 
    ON adm.hadm_id = trx.hadm_id
WHERE 
    (adm.diagnosis LIKE '%SEPSIS%' OR adm.diagnosis LIKE '%HEART FAILURE%')
    AND adm.admission_type = 'EMERGENCY'
    -- we only want the first transfer (admission) record
    AND trx.prev_careunit IS NULL
ORDER BY 
    adm.admittime DESC;

--query 2
SELECT 
    adm.subject_id,
    adm.insurance,
    adm.ethnicity,
    -- calculate length of stay in days and round to 2 decimals
    ROUND(CAST(EXTRACT(EPOCH FROM (adm.dischtime - adm.admittime))/(3600*24) AS NUMERIC), 2) AS days_stayed,
    trx.curr_careunit
FROM ADMISSIONS adm
JOIN TRANSFERS trx 
    ON adm.hadm_id = trx.hadm_id
WHERE 
    adm.hospital_expire_flag = 1 -- filter for patients who died
    AND trx.eventtype = 'admit'
ORDER BY 
    days_stayed DESC;


--query 3
SELECT 
    trx.hadm_id,
    trx.curr_careunit,
    -- casting the length of stay to make it cleaner
    CAST(trx.los AS DECIMAL(10,1)) AS icu_days,
    -- fill in null values with 'UNKNOWN'
    COALESCE(adm.discharge_location, 'UNKNOWN') AS discharge_to
FROM ADMISSIONS adm
JOIN TRANSFERS trx 
    ON adm.hadm_id = trx.hadm_id
WHERE 
    trx.los IS NOT NULL 
    AND trx.los > 10 -- =looking for long stays only
ORDER BY 
    trx.los DESC;


--query 4
SELECT 
    trx.curr_careunit,
    -- count how many admissions per unit
    COUNT(trx.hadm_id) AS total_admits,
    -- get the average stay for that unit
    ROUND(AVG(trx.los), 2) AS avg_stay_days
FROM TRANSFERS trx
JOIN ADMISSIONS adm 
    ON trx.hadm_id = adm.hadm_id
WHERE 
    adm.admission_type = 'EMERGENCY'
    AND trx.curr_careunit IS NOT NULL
GROUP BY 
    trx.curr_careunit
ORDER BY 
    avg_stay_days DESC;


--query 5
SELECT 
    adm.diagnosis,
    -- count total billing events for this diagnosis
    COUNT(cpt.cpt_cd) AS procedure_count,
    COUNT(DISTINCT adm.hadm_id) AS unique_patients
FROM ADMISSIONS adm
JOIN CPTEVENTS cpt 
    ON adm.hadm_id = cpt.hadm_id
WHERE 
    (adm.diagnosis LIKE '%SEPSIS%' OR adm.diagnosis LIKE '%PNEUMONIA%')
GROUP BY 
    adm.diagnosis
ORDER BY 
    procedure_count DESC;


--query 6
SELECT 
    adm.insurance,
    COUNT(adm.subject_id) AS total_patients,
    -- sum up the expire flags (1 = death)
    SUM(adm.hospital_expire_flag) AS total_deaths,
    -- calculate the percentage
    ROUND((CAST(SUM(adm.hospital_expire_flag) AS DECIMAL) / COUNT(adm.subject_id)) * 100, 2) AS death_rate_pct
FROM ADMISSIONS adm
JOIN TRANSFERS trx 
    ON adm.hadm_id = trx.hadm_id
WHERE 
    trx.eventtype = 'admit'
GROUP BY 
    adm.insurance
ORDER BY 
    death_rate_pct DESC;



--query 7
SELECT 
    adm.hadm_id,
    trx.curr_careunit,
    trx.los,
    -- categorize the risk based on length of stay
    CASE 
        WHEN trx.los < 2 THEN 'Low Risk (Short)'
        WHEN trx.los BETWEEN 2 AND 7 THEN 'Medium Risk (Standard)'
        WHEN trx.los > 7 THEN 'High Risk (Prolonged)'
        ELSE 'Unclassified'
    END AS risk_level
FROM TRANSFERS trx
JOIN ADMISSIONS adm 
    ON trx.hadm_id = adm.hadm_id
WHERE 
    adm.admission_type = 'EMERGENCY'
    AND trx.curr_careunit IS NOT NULL
ORDER BY 
    trx.los DESC;


--query 8
SELECT 
    adm.diagnosis,
    adm.hadm_id,
    trx.los,
    -- rank patients by stay length within their diagnosis group
    RANK() OVER (PARTITION BY adm.diagnosis ORDER BY trx.los DESC) AS ranking
FROM ADMISSIONS adm
JOIN TRANSFERS trx 
    ON adm.hadm_id = trx.hadm_id
WHERE 
    adm.diagnosis IN ('SEPSIS', 'CORONARY ARTERY DISEASE')
    AND trx.curr_careunit = 'MICU'
ORDER BY 
    adm.diagnosis, ranking;


-- query 9
SELECT 
    adm.hadm_id,
    adm.diagnosis,
    cpt.cpt_cd,
    dcpt.sectionheader AS category_name
FROM ADMISSIONS adm
JOIN CPTEVENTS cpt 
    ON adm.hadm_id = cpt.hadm_id
-- joining the dictionary table on the code range
JOIN D_CPT dcpt 
    ON dcpt.mincodeinsubsection <= cpt.cpt_cd 
    AND dcpt.maxcodeinsubsection >= cpt.cpt_cd
WHERE 
    adm.admission_type = 'EMERGENCY'
ORDER BY 
    adm.hadm_id;


-- query 10
-- first, count the transfers per admission
WITH TransferCounts AS (
    SELECT 
        hadm_id, 
        COUNT(*) as transfer_count
    FROM TRANSFERS
    WHERE eventtype = 'transfer'
    GROUP BY hadm_id
)
SELECT 
    adm.subject_id,
    adm.diagnosis,
    tc.transfer_count,
    adm.discharge_location
FROM ADMISSIONS adm
JOIN TransferCounts tc 
    ON adm.hadm_id = tc.hadm_id
WHERE 
    tc.transfer_count > 2 -- looking for unstable patients
ORDER BY 
    tc.transfer_count DESC;




