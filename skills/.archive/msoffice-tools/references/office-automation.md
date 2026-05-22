# Office Automation Ecosystem

## Microsoft Graph API (REST — cross-platform)
- Access Word, Excel, PowerPoint files stored in OneDrive/SharePoint
- Create, read, update files via HTTP requests
- Embed in web apps, automation scripts, serverless functions
- Requires Azure AD app registration + delegated permissions
- API endpoint: `https://graph.microsoft.com/v1.0/me/drive/...`
- Can co-author, track versions, and manage permissions remotely

## Office.js (JavaScript — browser + Office Add-ins)
- Build add-ins that run inside Word, Excel, PowerPoint (desktop + web)
- Excel: read/write ranges, tables, charts, PivotTables
- Word: manipulate content controls, paragraphs, OOXML
- PowerPoint: navigate slides, insert content, present
- Manifest XML defines add-in configuration
- Runs in embedded browser runtime (Edge WebView2 on Windows)

## VSTO (Visual Studio Tools for Office — Windows only)
- Full .NET framework for Office extensions
- Access to Office object model: Application, Workbooks, Slides, Documents
- Ribbon customization, task panes, form regions
- Deployment: ClickOnce, MSI installer, or network share
- Declining relevance — Microsoft recommends Office.js for new add-ins

## Open XML SDK (.NET — cross-platform)
- Direct manipulation of OPC packages (DOCX, XLSX, PPTX)
- No Office installation required
- Strongly-typed DOM for: WordprocessingDocument, SpreadsheetDocument, PresentationDocument
- Can validate against XSD schemas
- Power tool for server-side document generation
- Version 3.x+ is cross-platform (.NET 6+)

## Office Interop (COM — Windows only, Office required)
- C#/VB.NET control of running Office instances
- Full object model access (Word.Application, Excel.Application)
- Slow, process-heavy, not for server-side use
- Use only for legacy migration or desktop macros

## LibreOffice Headless (cross-platform, no license cost)
- `soffice --headless --convert-to pdf input.docx`
- Supports: docx, xlsx, pptx → pdf
- Also converts: docx → odt, xlsx → ods, pptx → odp
- Good for server-side conversion without Microsoft Office
