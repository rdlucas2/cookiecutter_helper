import subprocess
import unittest
from unittest.mock import patch, MagicMock, call
from repo_generator import get_configuration, clone_template_repo_and_generate_code, clone_and_push_to_github, main, Configuration

class RepoGeneratorTest(unittest.TestCase):
    local_configuration: Configuration = Configuration(
        project_name='fake_project',
        token='fake-token',
        overrides={'project_name': 'fake_project'},
        local_path='/some/local/path',
        template_url='https://github.com/example/template.git',
        extra_args=['project_name=fake_project'],
        repo_url='https://github.com/example/repo.git',
        commit_message="Add boilerplate",
        output_dir='fake/output_dir'
    )

    def setUp(self):
        self.mock_args = MagicMock()
        self.mock_args.template_url = 'https://github.com/example/template.git'
        self.mock_args.repo_url = 'https://github.com/example/repo.git'
        self.mock_args.token = 'fake-token'
        self.mock_args.json_file = 'path/to/fake.json'
        self.mock_args.output_dir = '/fake/output/dir'

    @patch('builtins.open', new_callable=unittest.mock.mock_open, read_data='{"project_name": "fake_project"}')
    def test_get_configuration(self, mock_file):
        configuration = get_configuration(self.mock_args)
        self.assertEqual(configuration.project_name, 'fake_project')
        self.assertEqual(configuration.local_path, f'{self.mock_args.output_dir}/fake_project')
        self.assertIn('project_name=fake_project', configuration.extra_args)

    @patch('subprocess.run')
    def test_clone_template_repo_and_generate_code(self, mock_run):
        clone_template_repo_and_generate_code(self.local_configuration)
        self.assertEqual(mock_run.call_count, 2)
        git_clone_call = mock_run.call_args_list[0]
        self.assertEqual(git_clone_call[0][0][0:2], ["git", "clone"])
        self.assertIn(self.local_configuration.template_url, git_clone_call[0][0])
        cookiecutter_call = mock_run.call_args_list[1]
        self.assertEqual(cookiecutter_call[0][0][0], "cookiecutter")

    @patch('glob.glob', return_value=['/some/local/path/file1', '/some/local/path/file2'])
    @patch('subprocess.run')
    def test_clone_and_push_to_github(self, mock_run, mock_glob):
        clone_and_push_to_github(self.local_configuration)
        self.assertEqual(mock_run.call_count, 7)
        # Verify git clone
        git_clone_call = mock_run.call_args_list[0]
        self.assertEqual(git_clone_call[0][0][0:2], ["git", "clone"])
        # Verify cp
        cp_call = mock_run.call_args_list[1]
        self.assertEqual(cp_call[0][0][0:2], ["cp", "-a"])
        # Verify git config uses cwd instead of os.chdir
        config_email_call = mock_run.call_args_list[2]
        self.assertIn('cwd', config_email_call[1])
        config_name_call = mock_run.call_args_list[3]
        self.assertEqual(config_name_call[0][0], ['git', 'config', 'user.name', 'Your Name'])
        # Verify git add, commit, push
        add_call = mock_run.call_args_list[4]
        self.assertEqual(add_call[0][0], ['git', 'add', '.'])
        commit_call = mock_run.call_args_list[5]
        self.assertEqual(commit_call[0][0], ['git', 'commit', '-m', 'Add boilerplate'])
        push_call = mock_run.call_args_list[6]
        self.assertIn('git', push_call[0][0])
        self.assertIn('push', push_call[0][0])

    @patch('subprocess.run')
    def test_clone_template_repo_and_generate_code_raises_on_failure(self, mock_run):
        mock_run.side_effect = subprocess.CalledProcessError(1, 'git')
        with self.assertRaises(subprocess.CalledProcessError):
            clone_template_repo_and_generate_code(self.local_configuration)

    @patch('glob.glob', return_value=[])
    @patch('subprocess.run')
    def test_clone_and_push_to_github_raises_on_failure(self, mock_run, mock_glob):
        mock_run.side_effect = subprocess.CalledProcessError(1, 'git')
        with self.assertRaises(subprocess.CalledProcessError):
            clone_and_push_to_github(self.local_configuration)

    @patch('argparse.ArgumentParser.parse_args')
    @patch('repo_generator.get_configuration')
    @patch('repo_generator.clone_template_repo_and_generate_code')
    @patch('repo_generator.clone_and_push_to_github')
    def test_main(self, mock_clone_and_push, mock_clone_and_generate, mock_get_config, mock_args):
        mock_args.return_value = self.mock_args
        mock_get_config.return_value = MagicMock()
        main(mock_args.return_value)
        mock_get_config.assert_called_once()
        mock_clone_and_generate.assert_called_once()
        mock_clone_and_push.assert_called_once()

if __name__ == '__main__':
    unittest.main()
