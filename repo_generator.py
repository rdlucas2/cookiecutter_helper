import os
import subprocess
import argparse
import json
import tempfile
from urllib.parse import urlparse
import glob

def clone_and_push_to_github(repo_url, local_path, token, commit_message="Add boilerplate"):
    """
    Clone an existing repository and push local code to it.
    """

    parsed_url = urlparse(repo_url)
    repo_name = parsed_url.path.split('/')[-1]
    #tmpdirname = f"/tmp/{repo_name}"
    #print(tmpdirname)

    with tempfile.TemporaryDirectory() as tmpdirname:
        # Git commands to clone the existing repository
        subprocess.run(["git", "clone", repo_url, tmpdirname])

        # copy the generated code to the cloned repository
        subprocess.run(["cp", "-a"] + glob.glob(f'{local_path}/*') + [tmpdirname])
        os.chdir(tmpdirname)
        #subprocess.run(["cd", {tmpdirname}])

        # Git commands to push the boilerplate code to the cloned repository
        subprocess.run(['git', 'config', '--global', "user.email", "you@example.com"])
        subprocess.run(['git', 'config', '--global', "user.name", "Your", "Name"])
        subprocess.run(['git', 'add', '.'])
        subprocess.run(['git', 'commit', '-m', commit_message])

        repo_url_with_pat = repo_url.replace("https://", f"https://{token}@")
        subprocess.run(['git', 'push', repo_url_with_pat])


def main(args):
    project_name = ''
    # Create a temporary directory
    with tempfile.TemporaryDirectory() as tmpdirname:
        # Step 0: Clone the cookiecutter template to the temporary directory
        subprocess.run(["git", "clone", args.template_url, tmpdirname])
        
        # Load the JSON data for overrides
        with open(args.json_file, 'r') as file:
            overrides = json.load(file)
        # Convert the JSON data into a string format suitable for `cookiecutter`
        extra_args = [f"{key}={value}" for key, value in overrides.items()]
        project_name = overrides.get("project_name")
        token = args.token
        # Step 1: Generate boilerplate code using the cloned template
        thing = ["cookiecutter", "-f", "--no-input", tmpdirname, "--output-dir", args.output_dir, *extra_args]
        print(f"{''.join(thing)}")
        subprocess.run(["cookiecutter", "-f", "--no-input", tmpdirname, "--output-dir", args.output_dir, *extra_args])

    # Step 2: Create new GitHub repository and push code
    local_path = f'{args.output_dir}/{project_name}'
    print(local_path)
    clone_and_push_to_github(args.repo_url, local_path, token)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Clone a cookiecutter template, generate a project from it, and push to GitHub.")
    parser.add_argument("--template_url", help="URL of the cookiecutter template on GitHub")
    parser.add_argument("--repo_url", help="URL of the existing GitHub repository")
    parser.add_argument("--token", help="GitHub Personal Access Token")
    parser.add_argument("--json_file", help="Path to the JSON file to override cookiecutter.json defaults")
    parser.add_argument("--output-dir", default=".", help="Directory where the boilerplate should be generated. Default is the current directory.")

    args = parser.parse_args()
    main(args)
