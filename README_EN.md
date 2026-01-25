**English** | [日本語](README.md)

# CovSnap

![Version](https://img.shields.io/badge/version-2.1.0-blue)
![Python](https://img.shields.io/badge/python-3.8+-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Coverity](https://img.shields.io/badge/Coverity-REST%20API%20v2-orange)
![Status](https://img.shields.io/badge/status-production-brightgreen)

Coverity Connect Snapshot Management Tool - REST API v2 Compatible

## Overview

A Python script that retrieves static analysis results (snapshots) from Coverity Connect and exports them in CSV format.

**Latest Update**: Completed full migration from SOAP API to REST API v2 on January 6, 2026 🎉

## Features

- ✅ **Snapshot Search**: Retrieve issues by project/stream/snapshot ID
- ✅ **CSV Export**: Export issue data in CSV format
- ✅ **Pagination Support**: Automatic retrieval of data exceeding 10,000 items
- ✅ **Detailed Information**: Complete data including individual CID details
- ✅ **REST API v2 Compatible**: Fully compatible with Coverity 2024.6.0 and later
- ✅ **Modular Architecture**: REST API client separated as an independent library

## 📁 File Structure

### Core Modules

- **`coverity_rest_lib.py`** (519 lines)
  - Coverity Connect REST API v2 client library
  - `CoverityRestClient` class: Retrieves project/stream/snapshot/issue information
  - Pagination support (handles large datasets over 10,000 items)
  - Reusable design (can be imported by other tools)

- **`cov_snap_standalone.py`** (926 lines)
  - Standalone CLI tool
  - Imports REST API client from `coverity_rest_lib`
  - Certified user management, email distribution, CSV/ZIP generation

- **`cov_check_auth_user_rest.py`**
  - Certified user authentication module via REST API

- **`archive/`** - Archive folder
  - Legacy version files (preserved for reference)

## Quick Start

### Requirements

- Python 3.8+
- Coverity Connect authentication credentials (auth-key)
- Required packages: `requests`, `urllib3`, `colorama` (optional)

### Installation

```powershell
# Clone repository
git clone https://github.com/keides2/cov_snap_pub.git
cd cov_snap_pub

# Install dependencies
pip install requests urllib3 colorama
```

### Environment Variables

Set the following environment variables before running the script:

```powershell
# Required environment variables
$env:COVAUTHUSER = "your_username"           # Coverity authentication username
$env:COVAUTHKEY = "your_auth_key"            # Coverity authentication key (32 characters)
$env:COVURL = "https://coverity.example.com:8080"  # Coverity Connect server URL

# Proxy settings (recommended)
$env:COVERITY_PROXY = "http://proxy.example.com:3128/"  # Coverity-specific proxy

# Or general proxy environment variables
$env:HTTPS_PROXY = "http://proxy.example.com:8080"      # HTTPS proxy
$env:HTTP_PROXY = "http://proxy.example.com:8080"       # HTTP proxy
```

**About actual configuration values**:
- The above `coverity.example.com` and `proxy.example.com` are examples
- **For actual server URLs, proxy URLs, and network paths, please contact your system administrator or security team**

**Proxy priority**:
1. `COVERITY_PROXY` - Coverity-specific proxy (highest priority)
2. `HTTPS_PROXY` - General HTTPS proxy
3. `HTTP_PROXY` - General HTTP proxy
4. Direct connection if not set

### Basic Usage

#### MODE 1: Local Save (Individual Execution)

Authenticated users retrieve snapshots for personal use:

```powershell
# Arguments: stream_name snapshot_id sender_email
python cov_snap_standalone.py my_project_stream 50183 user@example.com
```

**Operation**: 
1. Load stream-based address file (`{stream_name}_address.csv`)
2. Check certified user via Coverity REST API
3. Save CSV/ZIP locally if authentication succeeds

#### MODE 2: Email Distribution (Team Distribution)

Distribute to all certified users via email:

```powershell
# Arguments: stream_name snapshot_id
python cov_snap_standalone.py my_project_stream 50183
```

**Operation**:
1. Extract certified users from stream-based address file
2. Generate CSV/ZIP
3. Send email to all certified users

### Options

```powershell
# Verbose logging
python cov_snap_standalone.py my_project_stream 50183 --verbose

# Specify output directory
python cov_snap_standalone.py my_project_stream 50183 --output-dir C:\my_snapshots

# Skip authentication check (for development)
python cov_snap_standalone.py my_project_stream 50183 --no-auth
```

## 🛠️ Troubleshooting

### Common Issues

**Environment variable error (Error code 708)**:
```powershell
# Check environment variables
echo $env:COVAUTHUSER
echo $env:COVURL
echo $env:COVAUTHKEY
```

**HTTP 401 Unauthorized**:
- Verify authentication key is correct
- Verify username is correct

**Not a certified user (Error code 709)**:
- Check if email address is registered in address file
- Verify stream access permissions in Coverity Connect

**Connection error**:
- Check proxy settings
- Verify Coverity Connect server URL is correct
- Check firewall settings

## 📄 Error Codes

- `0`: Success
- `703`: Snapshot ID does not exist
- `706`: Zero issues found
- `708`: Environment variable error
- `709`: Not a certified user
- `712`: Address file not found
- `713`: Email sending failed

## 📞 Support

- **GitHub Issues**: https://github.com/keides2/cov_snap_pub/issues
- **Contact**: Project Administrator

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

**Version**: 2.1.0  
**Last Updated**: January 25, 2026
