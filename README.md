# Repo Generator with Cookiecutter

This application utilizes a `cookiecutter` template to generate boilerplate code for a project, and then creates a new repository on GitHub to push this code.

## Prerequisites

- Docker installed on your machine.
- A GitHub Personal Access Token (PAT) with permissions to create repositories. For generating one, follow the instructions [here](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token).

## Getting Started

1. **Clone this Repository**:
   
   ```bash
   git clone https://github.com/rdlucas2/cookiecutter_helper.git
   cd cookiecutter_helper
   ```

2. **Build the Docker Image**:

   ```bash
   #build artifact
   docker build -t repo-generator .

   #build tests
   docker build -t repo-generator-test . --target test
   ```

3. **Run the Application with Docker**:
   
   ```bash
      TEMPLATE_URL="https://github.com/cookiecutter-flask/cookiecutter-flask"
      GITHUB_TOKEN="YOUR_TOKEN_HERE"
      #REPO_NAME="improved-fiesta"
      REPO_URL="https://github.com/rdlucas2/improved-fiesta"
      JSON_FILE_PATH="/app/output/overrides.json"

      docker run -it -rm -v $(pwd)/generated_code:/app/output repo-generator $TEMPLATE_URL $REPO_URL $GITHUB_TOKEN $JSON_FILE_PATH --output-dir /app/output

      #debug:
      docker run -it --rm -v $(pwd)/generated_code:/app/output --entrypoint /bin/bash repo-generator

      #run tests (TODO: this calls pytest, but we need additional args or better default CMD):
      docker run -it --rm -v $(pwd):/coverage repo-generator-test
   ```
   ```powershell
      $TEMPLATE_URL="https://github.com/cookiecutter-flask/cookiecutter-flask"
      $GITHUB_TOKEN="YOUR_TOKEN_HERE"
      $REPO_URL="https://github.com/rdlucas2/improved-fiesta"
      $JSON_FILE_PATH="/app/output/overrides.json"

      docker run -it --rm -v "$(pwd)/generated_code:/app/output" repo-generator --template_url $TEMPLATE_URL --repo_url $REPO_URL --token $GITHUB_TOKEN --json_file $JSON_FILE_PATH --output-dir /app/output

      #debug:
      docker run -it --rm -v "$(pwd)/generated_code:/app/output" --entrypoint /bin/bash repo-generator

      #run tests (TODO: this calls pytest, but we need additional args or better default CMD):
      docker run -it --rm -v "$(pwd):/coverage" repo-generator-test
   ```

Replace placeholders like `TEMPLATE_URL`, `REPO_URL`, etc., with the appropriate values when running the container.

Note: If specifying an output directory within the container, the generated code will reside inside the Docker container's file system. If you want to access it from your host machine, consider mounting a volume or copying files out of the container.

## Parameters

- **TEMPLATE_URL**: The GitHub URL of the cookiecutter template.
  
- **REPO_NAME**: Name for the new GitHub repository to be created.
  
- **GITHUB_TOKEN**: Your GitHub Personal Access Token.

- **JSON_FILE_PATH**: Path to a JSON file containing overrides for the cookiecutter template. It should be formatted like:

  ```json
  {
      "variable_name1": "value1",
      "variable_name2": "value2"
  }
  ```

- **OUTPUT_DIR** (optional): Directory within the container where the boilerplate should be generated. Defaults to the current directory.

# Local SonarQube Setup with Docker

This guide will walk you through setting up SonarQube locally using Docker to scan your code for vulnerabilities.

## Prerequisites

- Docker installed on your local machine.
- Local codebase that you want to analyze.

## Getting Started

### 1. Pull SonarQube Docker Image

Pull the latest SonarQube image from Docker Hub:

```bash
docker pull sonarqube

#start sonarqube
docker run -d --name sonarqube -p 9000:9000 sonarqube

#monitor startup
docker logs -f sonarqube

#navigate to localhost:9000 when complete, using username/password of admin/admin

```

### 2. Running Analysis

```bash
docker run -it --rm -e SONAR_HOST_URL="http://host.docker.internal:9000" -e SONAR_LOGIN="<your-generated-token>" -v "$(pwd):/usr/src" sonarsource/sonar-scanner-cli
```

Remember to replace <your-generated-token> with the token you generate in SonarQube for authentication. This can be done in the SonarQube dashboard under your user account settings in the security section.

### 3. CVE SCAN

Remove ```--scanners vuln``` to enable secret scanning, but it will take longer.

```powershell
docker run -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd):/output" aquasec/trivy image --format table --output /output/trivy-report.txt --scanners vuln repo-generator:latest
docker run -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd):/output" aquasec/trivy image --format json --output /output/trivy-report.json --scanners vuln repo-generator:latest
```

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/output aquasec/trivy image --format table --output /output/trivy-report.txt --scanners vuln repo-generator:latest
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/output aquasec/trivy image --format json --output /output/trivy-report.json --scanners vuln repo-generator:latest
```

## License

This project is open source and available under the [MIT License](LICENSE).

---

### Other Notes:
- when changing file/directory permissions, sometimes need to delete anything generated from the scripts
