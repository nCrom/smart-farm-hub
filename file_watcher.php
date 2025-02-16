
<?php
// 파일 시스템 변경 감지 및 자동 Git 푸시 스크립트

// 로그 파일 설정
$log_file = 'git_sync.log';

// 환경 설정
$repo_path = 'D:/nCrom_server/xampp8.2/htdocs';
$branch = 'main';
$commit_message = '자동 커밋: 파일 시스템 변경 감지';

// 로깅 함수
function writeLog($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
}

// Git 상태 확인
function checkGitStatus() {
    global $repo_path;
    $output = shell_exec("cd $repo_path && git status --porcelain");
    return !empty($output);
}

// Git 풀 수행
function gitPull() {
    global $repo_path;
    $output = shell_exec("cd $repo_path && git pull 2>&1");
    writeLog("Git Pull 결과: $output");
    return $output;
}

// Git 커밋 및 푸시
function gitCommitAndPush() {
    global $repo_path, $branch, $commit_message;
    
    // 먼저 pull 수행
    gitPull();
    
    $commands = array(
        "cd $repo_path",
        "git add .",
        "git commit -m \"$commit_message\"",
        "git push origin $branch"
    );
    
    $command = implode(" && ", $commands);
    $output = shell_exec($command . " 2>&1");
    writeLog("Git Commit & Push 결과: $output");
    return $output;
}

// 메인 감시 루프
writeLog("파일 감시 시작");
while (true) {
    try {
        if (checkGitStatus()) {
            writeLog("변경사항 감지됨");
            $result = gitCommitAndPush();
            writeLog("동기화 완료");
        }
    } catch (Exception $e) {
        writeLog("에러 발생: " . $e->getMessage());
    }
    // 5초 대기 후 다시 체크
    sleep(5);
}
?>
