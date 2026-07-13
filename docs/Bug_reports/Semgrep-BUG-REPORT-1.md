Semgrep SAST Findings Report

Date: 13.07.2026

Summary:
Semgrep produced [15] real findings across the codebase, To count findigns accurately, result were parsed with "jq" rather than grep, which would count parse-level errors to security findings.

``` 
# Total findings
jq '.results | length' semgrep-results.json

# Findings by severity
jq -r '.results[] | .extra.severity' semgrep-results.json | sort | uniq -c
```
