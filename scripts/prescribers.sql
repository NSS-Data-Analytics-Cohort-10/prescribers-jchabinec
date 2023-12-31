-- MVP_QUESTIONS___________________________________________________________
-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
	SELECT
		npi,
		SUM(total_claim_count) AS total_claims
	FROM prescription
	GROUP BY npi
	ORDER BY SUM(total_claim_count) DESC
	LIMIT 1;
	-- ANSWER: NPI # 1881634483, with 99,707 claims.
	
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
	-- ** Check from previous answer **
	SELECT
		npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		specialty_description
	FROM prescriber
	WHERE npi = 1881634483;
-- ** Now let's do it right... **
	-- ** Start by finding the prescriber's name and find all records with that name **
	SELECT
		pr.npi,
		pr.nppes_provider_first_name,
		pr.nppes_provider_last_org_name,
		pr.specialty_description,
		ps.total_claim_count
	FROM prescriber AS pr
	INNER JOIN prescription AS ps
		USING(npi)
	WHERE npi IN
		(
		SELECT
			npi
		FROM prescription
		GROUP BY npi
		ORDER BY SUM(total_claim_count) DESC
		LIMIT 1
		);
	-- ** Now add all the rows up to get the total claims **
	-- ANSWER: Bruce Pendley, at a family practice, has the most claims


-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
	SELECT
		pr.specialty_description,
		SUM(ps.total_claim_count) AS total_claims
	FROM prescriber AS pr
	LEFT JOIN prescription AS ps
		USING(npi)
	WHERE ps.total_claim_count IS NOT NULL
	GROUP BY pr.specialty_description
	ORDER BY SUM(total_claim_count) DESC
	LIMIT 1;
	-- ** ANSWER: Family Practice had the most claims across all drugs, with 9,752,347.

--     b. Which specialty had the most total number of claims for opioids?
	SELECT
		pr.specialty_description,
		SUM(ps.total_claim_count) AS total_claims
	FROM prescriber AS pr
	LEFT JOIN prescription AS ps
		USING(npi)
	WHERE
		ps.total_claim_count IS NOT NULL
		AND drug_name IN
			(SELECT
				drug_name
			FROM drug
			WHERE
				opioid_drug_flag = 'Y'
			)
	GROUP BY pr.specialty_description
	ORDER BY SUM(total_claim_count) DESC
	LIMIT 1;
	-- ** ANSWER: Nurse Practitioner had the most opoid claims, with 900,845.

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
	SELECT
		pr.specialty_description,
		SUM(ps.total_claim_count) AS total_claims
	FROM prescriber AS pr
	LEFT JOIN prescription AS ps
		USING(npi)
	WHERE
		ps.total_claim_count IS NULL
	GROUP BY pr.specialty_description;
	-- ANSWER: Yes, there are 92 specialties with no associated prescriptions

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?


-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
	SELECT
		d.generic_name,
		CAST(p.total_drug_cost as money)
	FROM prescription AS p
	LEFT JOIN drug as d
		USING(drug_name)
	ORDER BY p.total_drug_cost DESC
	LIMIT 1;
	-- ANSWER: PIRFENIDONE, at a total cost of $2,829,174.30

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
	SELECT
		d.generic_name,
		CAST(p.total_drug_cost/p.total_day_supply as money) AS daily_cost
	FROM prescription AS p
	LEFT JOIN drug as d
		USING(drug_name)
	ORDER BY daily_cost DESC
	LIMIT 1;
	-- ANSWER: IMMUN GLOB G(IGG)/GLY/IGA OV50, at a total cost of $7,141.11 / day

-- ANSWER FROM Breakout Room discussion:
	SELECT
		generic_name,
		CAST(ROUND((SUM(total_drug_cost)/SUM(total_day_supply)),2)AS money) as cost_per_day
	FROM drug
	FULL JOIN prescription
		USING(drug_name)
	WHERE total_drug_cost IS NOT NULL
	GROUP BY generic_name
	ORDER BY cost_per_day DESC


-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
	SELECT
		drug_name,
		CASE
			WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type
	FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
	SELECT
		CASE
			WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither'
		END AS drug_type,
		CAST(SUM(p.total_drug_cost) AS money) AS total_spent
	FROM drug AS d
	LEFT JOIN prescription AS p
	USING(drug_name)
	GROUP BY drug_type
	ORDER BY total_spent DESC;
	-- ANSWER: More was spent on opioids than antibiotics.
	
	
-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
	SELECT
		DISTINCT(cbsa),
		cbsaname
	FROM cbsa
	WHERE
		cbsaname ILIKE '%, TN%';
	-- ANSWER: There are 10 CBSAs in Tennessee.
	
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
	SELECT
		c.cbsaname,
		SUM(p.population) AS total_population
	FROM cbsa AS c
	INNER JOIN population AS p
		USING(fipscounty)
	GROUP BY c.cbsaname
	ORDER BY total_population DESC;
	-- ANSWER: Nashville-Davidson--Murfreesboro--Franklin, TN has the largest population, with 1,830,410 people, while Morristown is teh smallest, with 116,352 people.
	
--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
	SELECT 
		f.county,
		f.state,
		TO_CHAR(p.population, 'fm999G999')
	FROM population AS p
	LEFT JOIN fips_county AS f
		USING(fipscounty)
	WHERE fipscounty NOT IN
		(
		SELECT
			fipscounty
		FROM cbsa
		)
	ORDER BY population DESC
	LIMIT 1;
	-- ANSWER: Sevier County, TN is the largest county not included in a CBSA.


-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
	SELECT
		drug_name,
		total_claim_count
	FROM prescription
	WHERE total_claim_count > 3000;
	--ANSWER: There are 9 drugs with more than 3000 total claims - see query above.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
	SELECT
		p.drug_name,
		CASE
			WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		END AS drug_type,
		p.total_claim_count
	FROM prescription AS p
	LEFT JOIN drug AS d
		USING(drug_name)
	WHERE total_claim_count > 3000;
	-- ANSWER: Of the 9 drugs with more than 3000 total claims, OXYCODONE HCL and HYDROCODONE-ACETAMINOPHEN are opioids.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
	SELECT
		pr.nppes_provider_last_org_name,
		pr.nppes_provider_first_name,
		ps.drug_name,
		CASE
			WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		END AS drug_type,
		ps.total_claim_count
	FROM prescription AS ps
	LEFT JOIN drug AS d
		USING(drug_name)
	LEFT JOIN prescriber AS pr
		USING(npi)
	WHERE total_claim_count > 3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
	SELECT
		p.npi,
		p.drug_name
	FROM prescription AS p
	LEFT JOIN drug AS d
	USING(drug_name)
	WHERE p.npi IN
		(
		SELECT
			npi
		FROM prescriber
		WHERE
			specialty_description ILIKE 'Pain Management'
			AND nppes_provider_city ILIKE 'Nashville'
		)
		AND d.opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    SELECT
		npi,
		drug_name,
		total_claim_count
	FROM prescription
	WHERE npi IN
		(
		SELECT
			npi
		FROM prescriber
		WHERE
			specialty_description ILIKE 'Pain Management'
			AND nppes_provider_city ILIKE 'Nashville'
		)
		opioid_drug_flag = 'Y';
	
	
	
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.