
<?php
require_once __DIR__ . '/src/GitWatcher/Config.php';
require_once __DIR__ . '/src/GitWatcher/Logger.php';
require_once __DIR__ . '/src/GitWatcher/LockManager.php';
require_once __DIR__ . '/src/GitWatcher/GitManager.php';

use GitWatcher\Config;
use GitWatcher\Logger;
use GitWatcher\GitManager;

// 저장소 경로 설정
$repo_path = __DIR__;
Config::init($repo_path);

// GitHub 토큰 확인
$github_token = getenv('GITHUB_TOKEN');
Logger::log("파일 감시 시작");
Logger::log("저장소 경로: $repo_path");
Logger::log("GitHub 토큰 설정 상태: " . ($github_token ? "설정됨" : "설정되지 않음"));

// 메인 루프
while (true) {
    if (GitManager::checkStatus()) {
        Logger::log("변경사항 감지됨 - 커밋 및 푸시 시도");
        GitManager::commitAndPush();
        Logger::log("동기화 완료");
    }
    sleep(2);
}
