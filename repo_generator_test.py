import unittest
from unittest.mock import patch, MagicMock
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
        mock_run.assert_called()

    @patch('subprocess.run')
    def test_clone_and_push_to_github(self, mock_run):
        clone_and_push_to_github(self.local_configuration)
        mock_run.assert_called()

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