A/B Testing & User Engagement Analysis in SQL 

Overview

This project simulates a real-world product analytics scenario where the goal is to evaluate the impact of a new ad campaign using A/B testing. Leveraging SQL Server and Tableau, I analyze user engagement metrics and conversion behavior across control and test groups, segmented by exposure levels, time, and activity patterns.

Objectives

- Evaluate the effectiveness of a new ad format vs. a control (PSA)
- Identify user segments with the highest conversion potential
- Simulate pre/post campaign behavior based on ad exposure
- Derive actionable product and marketing insights

Tools & Skills Used

- SQL Server Management Studio (SSMS) – Data cleaning, transformations, aggregations
- Excel – Dataset preparation and result exports

Dataset

- Source: [Kaggle - Marketing A/B Testing](https://www.kaggle.com/datasets/faviovaz/marketing-ab-testing?resource=download)
- Fields include:
  - `user id`, `test group`, `converted`, `total ads`, `most ads day`, `most ads hour`

Key Analyses

1. A/B Test Results
   - Test group conversion: 2.55%
   - Control group conversion: 1.79%
   - Statistically significant uplift (Chi-square = 54.3, p < 0.05)

2. Conversion by Exposure Stage
   - Pre (1–10 ads): 0.33%
   - Mid (11–25 ads): 1.02%
   - Post (26+ ads): 7.76%
   - Clear increase in conversion with higher ad exposure

3. CTR Analysis
   - Estimated CTR computed using `converted / total_ads`
   - Test group CTR exceeds control across exposure levels

4. Engagement Timing
   - Conversion analyzed by day of the week and hour of day
   - Identified peak engagement windows

5. User Segmentation
   - Users segmented into Low, Medium, and High activity buckets
   - High-activity users convert up to 15x more than low-activity

Key Takeaways

- Ad frequency has a strong positive correlation with conversions.
- Targeting **mid-engagement users** may yield high ROI.
- High-converting hours/days suggest **optimized scheduling** opportunities.
- The test campaign shows **statistically significant improvement** and justifies rollout.
