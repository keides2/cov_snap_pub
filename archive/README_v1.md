**English** | [日本語](README_ja.md)

# cov_snap (sanitized release)

This project provides utility scripts for Coverity® Connect snapshot collection, report generation, and automation of surrounding tasks such as bug-report exports and CSV packaging.

## Overview
- Gather snapshot metadata and issues for designated projects/streams.
- Package CSV outputs and optionally compress them for distribution.
- Support multi-step workflows (pure snapshot export, GitLab-integrated modes, Perforce-integrated mode).
- Companion scripts (e.g., `bug_report`, Outlook VBA scripts) automate e-mail delivery.
- Uses the shared `covautolib_3` module for Coverity REST API access.

## Features
- Configurable snapshot modes aligned with common operational cadences (3-day, 4-day, weekly, Perforce scenarios).
- Automated CSV gathering, ZIP packaging, and address-book based e-mail delivery.
- Optional Azure OpenAI integration (`bug_report_2.py`) for natural-language report drafting.

## Requirements
- Windows 10 or later
- Python 3.8+
- Git (for GitLab integration), Perforce CLI (if using Perforce mode)
- Microsoft Outlook (for automated mail delivery)
- Python packages: `suds-community`, `requests`, `pandas`, `openpyxl`

```bash
pip install suds-community requests pandas openpyxl
```

## Dependency on covautolib_3
`cov_snap.py` imports `covautolib_3` (`from covautolib import covautolib_3`). Ensure the module is accessible either by installing this repository’s sanitized covautolib package or adjusting `PYTHONPATH`:

```powershell
# Install sibling covautolib_pub as editable
pip install -e ..\covautolib_pub

# or temporarily extend PYTHONPATH
$env:PYTHONPATH = "C:\Users\HP\Docs\Security\covautolib_pub"
```

```bash
pip install -e ../covautolib_pub
export PYTHONPATH="$(pwd)/../covautolib_pub"
```

## Environment variables
Set the following before running scripts (PowerShell syntax shown):

```powershell
set COVAUTHUSER=your_username
set COVAUTHKEY=your_auth_key
set HTTP_PROXY=http://proxy.example.com:port/
set HTTPS_PROXY=http://proxy.example.com:port/
```

Other variables may be required depending on your deployment (see `.env.example` in `covautolib_pub`).

## Directory structure
Ensure working directories exist (adjust paths to suit your layout):
```
C:\cov\
C:\cov\groups\
C:\cov\log\
S:\path\to\config\
S:\path\to\address\
```

## Running cov_snap.py
Typical invocation patterns (adapt as needed):

```text
[cov_snap] cc_stream_name 14090
[cov_snap] gitlab_group_name cc_stream_name 14090
[cov_snap] gitlab_group_name gitlab_project_name gitlab_branch_name cc_group_name cc_stream_name 15076 sender@example.com
[cov_snap] p4_group_name //depot/p4_group_name/ head cc_group_name cc_stream_name 15048 sender@example.com
```

Corresponding batch helper (`cov_snap_2.bat`) mirrors the same argument order when e-mailing results.

## Auxiliary configuration
- `last.json`: runtime cache of processed snapshots (initially `[]`).
- Address book CSVs (e.g., `group_name_address.csv`, `group_name_address_auth.csv`) are used to look up distribution lists.

## API usage
- Primarily interacts with Coverity SOAP APIs; restructure or extend as needed for REST-based endpoints.
- Generated CSVs are zipped for transport and archival.
- Some routines expect Coverity dashboard filters to be preconfigured (“詳細ビュー” references in comments).

## Outlook automation
To send mail automatically, enable the included Outlook VBA script (`ThisOutlookSession_2.vba`). The batch files assume Outlook is configured and accessible.

## License
MIT License — see [LICENSE](LICENSE).

## Maintainer
Keisuke Shimatani (keides2)
