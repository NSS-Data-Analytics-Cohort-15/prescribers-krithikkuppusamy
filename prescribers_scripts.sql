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
	 CAST (SUM(CASE  WHEN opioid_drug_flag='Y' THEN prescription.total_drug_cost  END) AS money)AS opioid_cost,
	 CAST (SUM(CASE  WHEN antibiotic_drug_flag='Y' THEN prescription.total_drug_cost  END)AS money) AS antibiotic_cost
	
FROM drug
 JOIN prescription
	USING (drug_name)

/*
"Most money spent on opioid"	"$105,080,626.37"	"$38,435,121.26"	
*/	    	 
(
SELECT
	  CAST(SUM(prescription.total_drug_cost)AS money) AS money	
	,'opioid' AS drugname
FROM prescription 
	JOIN drug 
	  USING (drug_name)
WHERE opioid_drug_flag='Y'
)
UNION
(
SELECT
	  CAST(SUM(prescription.total_drug_cost)AS money) AS money
	 ,'antibiotic'	AS drugname
FROM 
	prescription 
	JOIN drug 
	  USING (drug_name)
WHERE antibiotic_drug_flag='Y'
)
ORDER BY money DESC

/*
"$105,080,626.37"	"opioid"
"$38,435,121.26"	"antibiotic"
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

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

select distinct(cbsaname) from cbsa

--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT 
	 drug_name
	,SUM(total_claim_count) AS total_count
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name
ORDER BY total_count

--select * from prescription


--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	 prescription.drug_name
	,SUM(total_claim_count) AS total_count
	,CASE 
	    WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid' END AS drugtype
FROM prescription
JOIN drug
	ON prescription.drug_name = drug.drug_name
WHERE total_claim_count >= 3000
GROUP BY prescription.drug_name,opioid_drug_flag
ORDER BY total_count


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

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prescriber.npi,drug.drug_name
FROM prescriber
--JOIN prescription
	--ON prescriber.npi=prescription.npi
 CROSS JOIN drug
	--ON prescription.drug_name = drug.drug_name
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND drug.opioid_drug_flag = 'Y'

--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi,drug.drug_name,total_claim_count--,SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
 LEFT JOIN prescription
	ON drug.drug_name=prescription.drug_name
  AND prescription.npi = prescriber.npi
	--ON prescription.drug_name = drug.drug_name
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND drug.opioid_drug_flag = 'Y'
--GROUP BY prescriber.npi,prescription.drug_name
 
--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi,drug.drug_name,COALESCE (total_claim_count,0)--,SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
CROSS JOIN drug
 LEFT JOIN prescription
	ON drug.drug_name=prescription.drug_name
  AND prescription.npi = prescriber.npi
	WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND drug.opioid_drug_flag = 'Y'
