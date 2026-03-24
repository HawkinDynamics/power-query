# Release Notes - v1.0.20260112
**Release Date:** January 12, 2026

**Release Type**
Patch Release (Bug Fixes & Template Updates)
----------

## Overview
This patch release addresses critical API endpoint URL construction issues discovered in the Template File directory and provides updated template files for both Power BI and Excel users. All users of the Template File workflow should upgrade to this version to ensure reliable API connectivity.

## 🐛 Critical Bug Fixes
### API Endpoint URL Construction
**Issue:** Missing forward slashes in API endpoint URL concatenation caused all data queries to fail with malformed URLs.

#### Resolution:

Added proper path separators (/) between base URL and endpoint paths across all data query files
Fixed organization name path handling in authentication function to prevent double-slash issues
Updated 6 core files to ensure proper URL formation

#### Files corrected:

- Template File/data-queries/Athletes.pq
- Template File/data-queries/Groups.pq
- Template File/data-queries/Tags.pq
- Template File/data-queries/Teams.pq
- Template File/data-queries/TestTypes.pq
- Template File/functions/funcAuth.pq

#### User Impact:

- **Before:** Users experienced connection failures when attempting to load data from API endpoints
- **After:** All API calls now construct valid URLs and connect successfully

#### Example Fix:

// Before (incorrect)
endpoint = url & "athletes"  // Results in: https://cloud.hawkindynamics.com/apiv1athletes

// After (correct)
endpoint = url & "/athletes"  // Results in: https://cloud.hawkindynamics.com/api/v1/athletes

----------

## 📦 Template File Updates
### Power BI Template (hd-api-template-v1.20260109.pbit)
- Incorporated all endpoint URL fixes
- Updated query logic for improved reliability
- Refreshed with latest data model structure
- File size: 199KB

### Excel Macro Template (hd-excel-template-v1.20260109.xltm)
- Applied endpoint URL corrections to all embedded queries
- Optimized macro code for better performance
- Reduced file size by ~10% (347KB → 310KB)
- Improved error handling in VBA routines

----------

## 🔧 Improvements
### Code Quality

- Enhanced code readability and maintainability across all Power Query scripts
- Standardized default API slug to v1 for consistency
- Improved organization structure within Template File directory

### Documentation
- Updated README.md with clearer instructions for Template File usage
- Added comprehensive release notes for v1.0 baseline
- Clarified differences between Template File, Parameterized, and Generics approaches

----------

## 📋 Upgrade Instructions
### For Power BI Users:
1. Download the latest hd-api-template-v1.20260109.pbit from the Template File directory
2. Open the template file in Power BI Desktop
3. Enter your Integration Key when prompted
4. Specify your Region and Organization ID (if applicable)
5. Click Load to populate your report with current data

### For Excel Users:
1. Download the latest hd-excel-template-v1.20260109.xltm from the Template File directory
2. Open the template in Excel (you may need to enable macros)
3. Follow the on-sheet instructions to configure your API credentials
4. Run the data refresh macro to load your latest test data

### For Custom Integration Users:
If you've customized any of the affected .pq files, review the endpoint URL construction in your code:

- Ensure all endpoint URLs use proper path separators: url & "/endpoint_name"
- Verify organization name handling doesn't produce double slashes
- Test all queries against your target API environment

----------

## ✅ Compatibility
- Backward Compatible: Yes - no breaking changes to data model or query structure
- Power BI Desktop: Compatible with all versions released in 2024-2026
- Excel: Compatible with Excel 2016 and later (Windows/Mac)
- API Version: Supports Hawkin Dynamics Cloud API v1.10

----------

__Previous Releases__
[v1.0.20260109](Release Notes v1.0.20260109.md) - Initial structured release with Template File, Parameterized, and Generics directories