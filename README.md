# Get Data Into Microsoft Excel and Power BI With Power Query

This is a collection of Power Query scripts to call Hawkin data into a Microsoft Excel or Power BI project using Hawkin Dynamic API Beta v1.10. 

#### Steps

1. Select Data Source
  - Find and Select the "Get Data" button in the "Home" tab of the window ribbon.
  - Find and select ‘Blank Query’ from the options to open the query window.

2. Open Script Editor
  - Select ‘Advanced Editor’ in the ‘Query’ section at the top of the window, in the ‘Home’ tab, to open the advanced editor window.

3. Replace Script and Key
  - Copy and paste the desired script into the script editor.
  - Replace the "YOUR_INTEGRATION_KEY" variable in the new script (on line 5) with your integration key created in your cloud site. Then press "Done".

> ###### Region Specific 
Ensure the URLs located in the `Source` and `Source2` variables are correct for your region. There is a specific URL prefix for each of the designated cloud regions:
  |    Region    |                   URL                   |
  |--------------|-----------------------------------------|
  |   Americas   |   "https://cloud.hawkindynamics.com"    |
  |    Europe    |  "https://eu.cloud.hawkindynamics.com"  |
  | Asia/Pacific | "https://apac.cloud.hawkindynamics.com" |
>

4. Review

You might be prompted to answer some specific questions about security. If you are asked to select an authentication method, you should choose “Anonymous”. You might also be asked to which level of the URL this should be applied. Selecting the base ‘https://cloud.hawkindynamics.com/api’ would work best, as it will apply to all queries above it (token and organization).

5. Repeat Steps

This sequence shows the steps you need to create a data call for an individual query. It is recommended that you use separate queries for each test type and other organizationally specific identifiers such as teams, groups, and athletes. You can repeat these same steps for each of the queries by using the appropriate script. 

> ###### Column Data Format
Ensure to check the format of the columns after running the scripts. Particularly the columns including numerical values. After running the scripts, the values in those columns are not assigned a format and will assumed as text. Be sure to check the returned data tables and assign the appropriate formats. 
>