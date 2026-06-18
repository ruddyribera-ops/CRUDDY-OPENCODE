# Mode-Specific Prompts and Output Formats

**describe:**
```
Provide a detailed description of this image. Include: main subject, setting/background,
colors/style, any text visible, notable objects, and overall composition.
```
Output:
```
## Image Description
[Detailed description...]
```

**ocr:**
```
Extract all text visible in this image verbatim. Preserve structure and formatting
(headers, lists, columns). If no text is found, say so.
```
Output:
```
## Extracted Text
[Preserved text structure...]
```

**ui-review:**
```
You are a UI/UX design reviewer. Analyze this interface mockup or design. Provide:
(1) Strengths — what works well, (2) Issues — usability or design problems,
(3) Specific, actionable suggestions for improvement. Be constructive and detailed.
```
Output:
```
## UI Design Review
### Strengths
- ...
### Issues
- ...
### Suggestions
- ...
```

**chart-data:**
```
Extract all data from this chart or graph. List: chart title, axis labels, all
data points/series with values if readable, and a brief summary of the trend.
```

**object-detect:**
```
List all distinct objects, people, and activities you can identify. For each,
describe what it is and its approximate location in the image.
```
