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
	  prescriber.npi--,specialty_description
FROM prescriber
  JOIN prescription
	ON prescriber.npi= prescription.npi
	where prescriber.npi != prescription.npi
--WHERE prescriber.npi <> prescription.npi

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
	 DISTINCT(drug.generic_name)
	,SUM (prescription.total_drug_cost) AS highest_drug_cost
FROM drug
JOIN prescription
		USING (drug_name)
GROUP BY drug.generic_name	
ORDER BY highest_drug_cost DESC
LIMIT 1




--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT 
	  drug_name
	, CASE  WHEN opioid_drug_flag='Y' THEN 'opioid'
	        WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	    	ELSE 'neither' END AS drug_type 
FROM drug

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	  drug_name
	, CASE  WHEN opioid_drug_flag='Y' THEN 'opioid'
	        WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	    	ELSE 'neither' END AS drug_type 
FROM drug
 JOIN prescription
	USING (drug_name)
      CASE  WHEN DRUG_TYPE THEN SUM(prescription.total_drug_cost) END AS money
	        --WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	    	--ELSE 'neither' END AS drug_type 

--5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(cbsaname) AS total_cbsa_tn
FROM cbsa
WHERE cbsaname ILIKE '%TN';

/*
"total_cbsa_tn"
33
*/

--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT distinct(fipscounty) from cbsa