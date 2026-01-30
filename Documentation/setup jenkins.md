## Job Creation

- Jenkins → New Item
- Select Pipeline
- Job name: `<project-name>-pipeline`

## Pipeline Definition

- Pipeline script from SCM
- SCM: Git
- Repository URL
- Credentials: `git-credentials`
- Branch: `*/main`
- Script Path: `Jenkinsfile`