# edgecast-cdn-report

## Introduction

This script will help you generate a text report of your current month Edgecast CDN data transfer.
It displays data broken down by your individual CNAMEs that can be grouped based on your config.

The report output looks as follows:

```
Date : 2015-01-08 
+---------------------------------------------------+-----------+-----------+------------+
| CNAME                                             | Cur MTD   | Last MTD  | Last Total |
+---------------------------------------------------+-----------+-----------+------------+
| Total                                             | 22.84 GB  |           | 99.73 GB   |
+---------------------------------------------------+-----------+-----------+------------+
| Unaccounted                                       | 2.23 GB   |           | 15.15 GB   |
+---------------------------------------------------+-----------+-----------+------------+
| STAGING_ASSETS_FAKEDOMAIN_A                       | 283.63 MB | 493.56 MB | 1.41 GB    |
| cdn0-e.staging.fakedomain-a.static.com            | 118.14 MB | 151.29 MB | 455.32 MB  |
| cdn-e.staging.fakedomain-a.static.com             | 92.86 MB  | 152.35 MB | 450.74 MB  |
| cdn1-e.staging.fakedomain-a.static.com            | 72.63 MB  | 189.93 MB | 498.99 MB  |
+---------------------------------------------------+-----------+-----------+------------+
| STAGING_ASSETS_FAKEDOMAIN_B                       | 168.26 MB | 267.08 MB | 951.3 MB   |
| cdn0-e.staging.fakedomain-b.static.com            | 98.66 MB  | 142.35 MB | 555.5 MB   |
| cdn1-e.staging.fakedomain-b.static.com            | 69.6 MB   | 124.74 MB | 395.8 MB   |
+---------------------------------------------------+-----------+-----------+------------+

```

## Installation

0. Pre-requisites - ensure you have a working Ruby setup and have the bundler gem installed.

1. Checkout this repo
  `git clone https://github.com/KMK-ONLINE/edgecast-cdn-report.git`
  
2. Install dependencies
  `cd edgecast-cdn-report; bundle`
  
3. Copy the sample config file and customize it
  ` cp config_sample.yml config.yml`
  The `token` should be the API token available on your Edgecast control panel. Your `customer_id` 
  is also available via your control panel.
  
## Running

Once the configuration file is created just run 

`rake`

If the configuration file is named differently or located in a different directory run it as follows

`rake default[/path/to/config.yml]`
