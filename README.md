# Dependency Review Script
This script checks for vulnerabilities in the dependencies of a GitHub repository by comparing two branches or commits. It uses the [GitHub API](https://docs.github.com/en/rest/dependency-graph/dependency-review?apiVersion=2022-11-28#get-a-diff-of-the-dependencies-between-commits) to fetch the dependency graph and analyze the vulnerabilities.

## Prerequisites
`curl`: Command-line tool for making HTTP requests.

`jq`: Command-line JSON processor.

GitHub Personal Access Token with `repo` scope.

## Usage
```
./dep-review.sh <org_name> <repo_name> <base> <head> <severity_threshold> <github_token>
```

`<org_name>`: The GitHub organization name.

`<repo_name>`: The GitHub repository name.

`<base>`: The base branch or commit SHA.

`<head>`: The head branch or commit SHA.

`<severity_threshold>`: The severity threshold (e.g., low, medium, high, critical).

`<github_token>`: Your GitHub Personal Access Token.

## Example
```
./dep-review.sh my-org my-repo main feature-branch medium my-github-token
```

## Script Details
1. **API Request**: The script constructs a URL to compare the dependencies between the base and head commits/branches and makes a request to the GitHub API.
1. **Response Logging**: The script logs the response data from the API.
1. **Vulnerability Check**: It checks if there are any vulnerabilities in the response.
1. **Severity Check**: For each vulnerability, it checks if the severity meets or exceeds the specified threshold.
1. **Output**:
    - If no vulnerabilities are found, it prints "No vulnerabilities found" and exits with status 0.
    - If a vulnerability meets or exceeds the severity threshold, it prints a message and exits with status 1.
    - If no vulnerabilities meet or exceed the severity threshold, it prints a message and exits with status 0.
## Exit Codes
  - `0`: No vulnerabilities found or no vulnerabilities meet/exceed the severity threshold.
  - `1`: Vulnerability found that meets/exceeds the severity threshold.

## Example Output
```
API Response: { ... }
No vulnerabilities found
```

or

```
API Response: { ... }
Processing vulnerability: { ... }
Severity: high, Index: 3, Threshold Index: 2
Vulnerability found with severity high!
```

## Notes

* Ensure you have the necessary permissions and scopes for your GitHub Personal Access Token.
* The script uses `jq` to process JSON responses. Make sure `jq` is installed and available in your PATH.

## License
This script is licensed under the MIT License. See the LICENSE file for more details.
