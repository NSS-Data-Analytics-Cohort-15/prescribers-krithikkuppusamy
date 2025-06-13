SELECT * FROM cbsa;
SELECT * FROM public.fips_county
SELECT * FROM public.drug;
SELECT * FROM public.overdose_deaths
SELECT * FROM public.population
SELECT * FROM public.zip_fips
SELECT * FROM public.prescription
SELECT * FROM public.prescriber

--1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi,SUM(total_claim_count) AS total_claim
FROM prescription
--where npi=1912087008
GROUP BY npi
ORDER BY total_claim DESC
LIMIT 1

/*
"npi"	"total_claim"
1881634483	99707
*/


--1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	 npi
	,nppes_provider_first_name
	,nppes_provider_last_org_name
	,specialty_description
	,SUM(total_claim_count) AS total_claim
FROM 	prescription
JOIN	prescriber
USING (npi)
GROUP BY 
	 npi
	,nppes_provider_first_name
	,nppes_provider_last_org_name
	,specialty_description
ORDER BY total_claim DESC
LIMIT 1

/*
"npi"	"nppes_provider_first_name"	"nppes_provider_last_org_name"	"specialty_description"	"total_claim"
1881634483	"BRUCE"	"PENDLEY"	"Family Practice"	99707
*/

--2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 
	 specialty_description
	,SUM(total_claim_count) AS total_claim
FROM 	prescription
JOIN	prescriber
USING (npi)
GROUP BY 
	specialty_description
ORDER BY total_claim DESC
LIMIT 1

/*
"specialty_description"	"total_claim"
"Family Practice"	9752347
*/

-- 2b. Which specialty had the most total number of claims for opioids?

SELECT 
	 specialty_description
	,SUM(total_claim_count) AS total_claim
FROM prescription
JOIN prescriber USING (npi)
JOIN drug 
	ON prescription.drug_name=drug.drug_name
		AND opioid_drug_flag ILIKE 'Y'
--WHERE opioid_drug_flag ILIKE 'Y'
GROUP BY 
	 specialty_description 
ORDER BY total_claim DESC	 
LIMIT 1

/*
"specialty_description"	"total_claim"
"Nurse Practitioner"	900845
*/

--2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT  
	  DISTINCT (prescriber.specialty_description)
FROM prescriber
LEFT JOIN prescription
	ON prescriber.npi= prescription.npi
WHERE prescription.npi IS NULL

--ANS Total rows=92

	
--3 a. Which drug (generic_name) had the highest total drug cost?
--select distinct(drug_name) from prescription
SELECT 
	 DISTINCT(drug.generic_name)
	,SUM (prescription.total_drug_cost) AS highest_drug_cost
FROM drug
JOIN prescription
		USING (drug_name)
GROUP BY drug.generic_name	
ORDER BY highest_drug_cost DESC
LIMIT 1

/*
"generic_name"	"highest_drug_cost"
"INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35
*/
SELECT 
	 DISTINCT(drug.generic_name)
	,MAX (prescription.total_drug_cost) AS highest_drug_cost
FROM drug
JOIN prescription
		USING (drug_name)
GROUP BY drug.generic_name	
ORDER BY highest_drug_cost DESC
LIMIT 1

/*
"generic_name"	"highest_drug_cost"
"PIRFENIDONE"	2829174.3
*/
--3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT 
	 DISTINCT(drug.generic_name),ROUND((prescription.total_drug_cost/prescription.total_day_supply),2) AS drug_cost
FROM drug
JOIN prescription
		USING (drug_name)
ORDER BY drug_cost DESC
LIMIT 1

/*
"generic_name"	"drug_cost"
"IMMUN GLOB G(IGG)/GLY/IGA OV50"	7141.11
*/

--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT 
	  drug_name
	, CASE  WHEN opioid_drug_flag='Y' THEN 'opioid'
	        WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	    	ELSE 'neither' END AS drug_type 
FROM drug

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
		CASE 
			WHEN (SUM(CASE  WHEN opioid_drug_flag='Y' THEN prescription.total_drug_cost  END) > SUM(CASE  WHEN antibiotic_drug_flag='Y' THEN prescription.total_drug_cost  END)) THEN 'Most money spent on opioid' ELSE 'Most money spent on antibiotic'  END,
	 SUM(CASE  WHEN opioid_drug_flag='Y' THEN prescription.total_drug_cost  END) AS opioid_cost,
	SUM(CASE  WHEN antibiotic_drug_flag='Y' THEN prescription.total_drug_cost  END) AS antibiotic_cost
	
FROM drug
 JOIN prescription
	USING (drug_name)

	
	    	 
(
SELECT
	  SUM(prescription.total_drug_cost) AS money	
	,'opioid' AS drugname
FROM prescription 
	JOIN drug 
	  USING (drug_name)
WHERE opioid_drug_flag='Y'
)
UNION
(
SELECT
	  SUM(prescription.total_drug_cost) AS money
	 ,'antibiotic'	AS drugname
FROM 
	prescription 
	JOIN drug 
	  USING (drug_name)
WHERE antibiotic_drug_flag='Y'
)
ORDER BY money DESC

/*
"money"	"drugname"
105080626.37	"opioid"
38435121.26	"antibiotic"
*/

	
--5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(cbsaname) AS total_cbsa_tn
FROM cbsa
WHERE cbsaname LIKE '%TN%';
--select distinct cbsaname from cbsa where cbsaname like '%TN%'
/*
"total_cbsa_tn"
56
*/

--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT 
	  cbsa.cbsaname
	, SUM(population) AS total_population
FROM cbsa
JOIN population
	ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY total_population DESC


/*"cbsaname"	"total_population"
"Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410
"Morristown, TN"	116352*/

select distinct(cbsaname) from cbsa

--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT 
	 drug_name
	,SUM(total_claim_count)
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name

--select * from prescription


--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	 prescription.drug_name
	,SUM(total_claim_count)
	,CASE 
	    WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid' END AS drugtype
FROM prescription
JOIN drug
	ON prescription.drug_name = drug.drug_name
WHERE total_claim_count >= 3000
GROUP BY prescription.drug_name,opioid_drug_flag

-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	 prescription.drug_name,prescription.npi
	,SUM(total_claim_count)
	,CASE 
	    WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid' END AS drugtype
	,CASE
	 	WHEN prescription.npi = pbr.npi THEN pbr.nppes_provider_first_name--,pbr.nppes_provider_last_org_name
	    END AS prescribername
FROM prescription
JOIN drug
	ON prescription.drug_name = drug.drug_name
JOIN prescriber AS pbr
	ON prescription.npi = pbr.npi
WHERE total_claim_count >= 3000
GROUP BY prescription.drug_name,opioid_drug_flag,prescription.npi,pbr.npi,pbr.nppes_provider_first_name--,pbr.nppes_provider_last_org_name