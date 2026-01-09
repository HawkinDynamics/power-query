# **Hawkin Dynamics Power Query Scripts**

Welcome to the official Hawkin Dynamics Power Query repository. This comprehensive collection of scripts and templates is designed to streamline your workflow by enabling you to pull athlete performance data directly from the Hawkin Dynamics Cloud API into your preferred analysis tools—specifically Microsoft Power BI and Excel—using the Power Query (M) formula language.

Whether you are building a simple weekly report or a complex historical analysis dashboard, these tools bridge the gap between your raw force plate data and actionable insights.

## **Repository Structure**

To better serve our diverse user base—ranging from coaches who want a quick dashboard to data scientists building custom integrations—we have completely reorganized the repository into three distinct categories. Please select the folder that best aligns with your technical comfort level and reporting needs:

### **1\. Template File (Recommended for Beginners)**

**Location:** /Template File

This is the absolute fastest way to get started. We have pre-packaged a Power BI Template (.pbit) that contains all the necessary queries and relationships pre-configured for you.

* **Contains:** hd-api-template.pbit (and supporting source code).  
* **Why use this?**  
  * **Zero Coding:** You do not need to write or edit a single line of code.  
  * **Instant Structure:** Tables for Athletes, Teams, and Test Types are automatically linked.  
  * **Lightweight:** The file contains the *structure* of the report but none of the data, making it easy to email and share.  
* **How to use:**  
  1. Double-click the .pbit file to open it in Power BI Desktop.  
  2. A native Power BI pop-up window will appear asking for your parameters.  
  3. Paste your Integration Key into the field. You can also specify a Region (e.g., Americas, Europe) or Organization ID if applicable.  
  4. Click **Load**. Power BI will automatically connect to the API, build the data model, and populate your tables with your latest test data.

### **2\. Parameterized Scripts (Best for Power Users)**

**Location:** /Parameterized

These scripts are optimized for scalability and maintenance using **Power BI Parameters**. Instead of hardcoding your credentials into every individual script, these queries are designed to reference a single set of global variables (Parameters) that you define once in your Power BI environment.

* **Best for:** Users building robust, multi-query reports. If you need to update your API Key or change the specific time range for your analysis, you only need to update the Global Parameter once, and every script in your report will automatically inherit the new value. This prevents the error-prone process of finding and replacing keys in a dozen different files.  
* **How to use:**  
  1. **Create Parameters:** Open Power BI Desktop and navigate to **Home** \> **Transform Data** \> **Manage Parameters**. Create the following parameters (names must match exactly):  
     * SecretKey (Text): Paste your unique Integration Key here.  
     * orgName (Text): Enter your Organization ID (or leave blank/null if not applicable).  
     * reg (Text): Enter your region (e.g., "Americas", "Europe", or "Asia/Pacific").  
  2. **Import the Script:** Open the desired script file (e.g., SquatJump.pq) from this folder in a text editor and copy the content.  
  3. **Create Query:** In Power BI, go to **Home** \> **Get Data** \> **Blank Query**.  
  4. **Paste Code:** Open the **Advanced Editor**, paste the code, and click **Done**.  
  5. **Result:** The query will immediately execute by pulling the values from the parameters you created in Step 1\.

### **3\. Generics (Legacy / Manual Edit)**

**Location:** /Generics

These are standard, standalone scripts where configuration variables are explicitly defined at the top of the file. This was the original method for connecting to the API.

* **Best for:** Learning how the API works, performing simple one-off data pulls, or debugging in VS Code. Because the logic is exposed in a linear fashion, it is easier to step through the "Applied Steps" in Power BI to see exactly where a connection might be failing.  
* **How to use:**  
  1. Open the script file (e.g., SquatJump.pq) in a text editor.  
  2. Locate the **Configuration Section** at the very top of the code.  
  3. Manually edit the variables:  
     * Replace YOUR\_INTEGRATION\_KEY with your actual key.  
     * Update Region or TestType IDs as needed.  
  4. Copy the entire script and paste it into Power BI's **Advanced Editor**.

## **Prerequisites**

To successfully use these scripts, ensure you have the following:

* **Microsoft Power BI Desktop:** We recommend the latest monthly version. It is a free download from the Microsoft Store or the official website.  
* **Hawkin Dynamics Integration Key:**  
  * This is *not* your login password.  
  * To find it, log in to the Hawkin Cloud, go to **Settings** \> **Integrations**, and copy your unique API Key.  
  * *Security Note:* Treat this key like a password. Do not share it in public forums or commit it to public code repositories.

## **Support & Troubleshooting**

* **Column Formatting:** After loading data, always check your column types. Power Query may occasionally default numeric columns (like "Jump Height") to "Text". You can fix this by selecting the column and changing the "Data Type" in the Transform tab.  
* **API Documentation:** For deep technical details on rate limits, specific data points, or field definitions, please refer to the API docs PDF found in the repo.