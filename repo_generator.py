import os
import subprocess
import argparse
import json
import tempfile
import glob
from collections import namedtuple

Configuration = namedtuple('Configuration', 'project_name token overrides local_path template_url extra_args repo_url commit_message output_dir')

def get_configuration(args):
    with open(args.json_file, 'r') as file:
        overrides = json.load(file)
    project_name: str = overrides.get("project_name")
    local_path = f'{args.output_dir}/{project_name}'
    return Configuration(
        project_name=project_name, 
        token=args.token, 
        overrides=overrides, 
        local_path=local_path, 
        template_url=args.template_url, 
        extra_args=[f"{key}={value}" for key, value in overrides.items()],
        repo_url=args.repo_url,
        commit_message="Add boilerplate",
        output_dir=args.output_dir
    )

def clone_template_repo_and_generate_code(configuration: Configuration):
    with tempfile.TemporaryDirectory() as tmpdirname:
        subprocess.run(["git", "clone", configuration.template_url, tmpdirname])
        command = ["cookiecutter", "-f", "--no-input", tmpdirname, "--output-dir", configuration.output_dir, *configuration.extra_args]
        print(f"{' '.join(command)}")
        subprocess.run(command)

def clone_and_push_to_github(configuration: Configuration):
    """
    Clone an existing repository and push local code to it.
    """

    with tempfile.TemporaryDirectory() as tmpdirname:
        # Git commands to clone the existing repository
        subprocess.run(["git", "clone", configuration.repo_url, tmpdirname])

        # copy the generated code to the cloned repository
        subprocess.run(["cp", "-a"] + glob.glob(f'{configuration.local_path}/*') + [tmpdirname])
        os.chdir(tmpdirname)
        #subprocess.run(["cd", {tmpdirname}])

        # Git commands to push the boilerplate code to the cloned repository
        subprocess.run(['git', 'config', '--global', "user.email", "you@example.com"])
        subprocess.run(['git', 'config', '--global', "user.name", "Your", "Name"])
        subprocess.run(['git', 'add', '.'])
        subprocess.run(['git', 'commit', '-m', configuration.commit_message])

        repo_url_with_pat = configuration.repo_url.replace("https://", f"https://{configuration.token}@")
        subprocess.run(['git', 'push', repo_url_with_pat])

def main(args):
    configuration: Configuration = get_configuration(args)
    clone_template_repo_and_generate_code(configuration)
    clone_and_push_to_github(configuration)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Clone a cookiecutter template, generate a project from it, and push to GitHub.")
    parser.add_argument("--template_url", help="URL of the cookiecutter template on GitHub")
    parser.add_argument("--repo_url", help="URL of the existing GitHub repository")
    parser.add_argument("--token", help="GitHub Personal Access Token")
    parser.add_argument("--json_file", help="Path to the JSON file to override cookiecutter.json defaults")
    parser.add_argument("--output-dir", default=".", help="Directory where the boilerplate should be generated. Default is the current directory.")

    args = parser.parse_args()
    main(args)
