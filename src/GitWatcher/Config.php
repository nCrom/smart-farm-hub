
<?php
namespace GitWatcher;

class Config {
    public static $repo_path;
    public static $branch = 'main';
    public static $commit_message = 'Auto-commit by file watcher';
    public static $log_file = 'git_sync.log';
    public static $lock_file = 'git_sync.lock';
    public static $excluded_files = ['git_sync.log', 'webhook.log', '.git'];
    
    public static function init($repo_path) {
        self::$repo_path = $repo_path;
        shell_exec('chcp 65001'); // UTF-8 인코딩 설정
    }
}
