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
