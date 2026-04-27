# Google Sheets MCP (bug form responses)

This project uses **[xing5/mcp-google-sheets](https://github.com/xing5/mcp-google-sheets)** so Cursor (or any MCP client) can read and update the **Google Sheet** that receives **Google Forms** bug reports. The MCP talks to the **Sheets API** and **Drive API**; it does not call the Forms API.

**Secrets:** Service account JSON keys, OAuth client files, and Base64 `CREDENTIALS_CONFIG` stay **out of git**. Store them under e.g. `~/.config/finko-mcp/` and reference absolute paths in **Cursor → Settings → MCP** (user config, not this repo).

## Prerequisites

1. **[uv](https://docs.astral.sh/uv/)** installed so `uvx` is on your `PATH` (or use the full path to `uvx` in MCP config on macOS if `spawn uvx ENOENT` appears).
2. **Google Cloud:** one project with **Google Sheets API** and **Google Drive API** enabled.
3. **Credentials** (pick one):
   - **Service account (recommended):** JSON key; share access with the service account **email** (`client_email` in the JSON).
   - **OAuth:** Desktop app client JSON + writable `TOKEN_PATH` for the first browser login (see upstream README).

## Service account + Form-linked spreadsheet

Upstream expects:

| Variable | Purpose |
|----------|---------|
| `SERVICE_ACCOUNT_PATH` | Absolute path to the service account **JSON key** file. |
| `DRIVE_FOLDER_ID` | A **Drive folder** ID (`https://drive.google.com/drive/folders/<ID>`) that is **shared with the service account** (Editor). Used as default context for listing/creating files. |

**Bug sheet access:** Put the **responses spreadsheet** inside that shared folder (**File → Move** in Google Drive), **or** keep it elsewhere but **also share the spreadsheet file** with the service account email (Editor if agents should update cells, Viewer if read-only). `get_sheet_data` uses the **spreadsheet ID** from the sheet URL; the SA must have permission on that file.

**IDs:** Spreadsheet ID is the segment in `https://docs.google.com/spreadsheets/d/<spreadsheetId>/edit`. The responses tab is often **`Form responses 1`** (confirm in the sheet UI).

## Cursor MCP configuration

Add a server block to your **user** MCP JSON ([Cursor MCP](https://docs.cursor.com/context/mcp)). Example for **service account** + **tool filtering** (fewer tools ≈ smaller context; adjust the list as needed):

```json
{
  "mcpServers": {
    "google-sheets-bugs": {
      "command": "uvx",
      "args": [
        "mcp-google-sheets@latest",
        "--include-tools",
        "get_sheet_data,update_cells,list_sheets,list_spreadsheets"
      ],
      "env": {
        "SERVICE_ACCOUNT_PATH": "/Users/YOU/.config/finko-mcp/finko-bugs-sa.json",
        "DRIVE_FOLDER_ID": "YOUR_DRIVE_FOLDER_ID"
      }
    }
  }
}
```

On **macOS**, if `uvx` is not found, set `"command"` to the full path reported by `which uvx` (often under `~/.local/bin/uvx`).

Equivalent tool filter via env instead of args: `ENABLED_TOOLS=get_sheet_data,update_cells,list_sheets,list_spreadsheets` (comma-separated, **no spaces**—see upstream README).

## Agent usage tips

- Read recent rows: `get_sheet_data` with `spreadsheet_id`, `sheet` (e.g. `Form responses 1`), optional `range` (e.g. `A1:H50`).
- Triage write-back: add columns like **Status** / **Notes** / **PR** in the sheet header row, then `update_cells` with a precise A1 range.
- Full tool list and parameters: [upstream README — Available Tools](https://github.com/xing5/mcp-google-sheets#%EF%B8%8F-available-tools--resources).

## Alternatives (not this doc)

- **OAuth** instead of SA: set `CREDENTIALS_PATH` / `TOKEN_PATH` per upstream; no `DRIVE_FOLDER_ID` required in the same way—see their **Method B** table.
- **Public sheet + API key only:** not supported by this MCP; see internal planning or a tiny custom read-only MCP if you need that later.

## Revision log

| Date | Change |
|------|--------|
| 2026-04-27 | Initial doc: **xing5/mcp-google-sheets** via `uvx`, SA + `DRIVE_FOLDER_ID`, Cursor config template, tool filtering for bug triage. |
