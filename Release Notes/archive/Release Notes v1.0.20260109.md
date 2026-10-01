# **Release Notes \- v1.0.20260109**

## **Overview**

This release introduces a major structural refactor of the Power Query repository to improve usability for both non-technical users and developers. The flat-file structure has been replaced with a categorized approach.

## **Key Changes**

### **🚀 New Features**

- **Power BI Template File:** Added hd-api-template.pbit. This allows users to instantiate a full Power BI report environment simply by entering their Integration Key, removing the need to copy-paste code.
- **Parameterized Functions:** Added a /Parameterized directory containing functionalized versions of all API endpoints. These scripts accept arguments (Region, Key, Date Ranges) via the Power BI native UI.

### **📦 Repository Organization**

- **Folder Restructure:**
  - Moved original standalone scripts to /Generics.
  - Created /Template File directory for the .pbit and its dependencies.
  - Created /Parameterized directory for function-based queries.
- **Standardization:** organized scripts into clear subcategories (e.g., Call by test type vs root level entities like Athletes).

### **🛠 Improvements**

- Updated README.md to reflect the new workflows.
- Added VS Code settings for better developer experience when editing .pq files.
