
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
    writeLog("Git 상태 확인: " . ($output ? "변경사항 있음" : "변경사항 없음"));
    return !empty($output);
}

// Git 풀 수행
function gitPull() {
    global $repo_path;
    writeLog("Git Pull 시작");
    $output = shell_exec("cd $repo_path && git pull origin main 2>&1");
    writeLog("Git Pull 결과: $output");
    return $output;
}

// Git 커밋 및 푸시
function gitCommitAndPush() {
    global $repo_path, $branch, $commit_message;
    
    // 현재 브랜치 확인
    $current_branch = trim(shell_exec("cd $repo_path && git rev-parse --abbrev-ref HEAD"));
    writeLog("현재 브랜치: $current_branch");
    
    if ($current_branch !== $branch) {
        writeLog("브랜치 전환: $branch");
        shell_exec("cd $repo_path && git checkout $branch");
    }
    
    // 변경사항 스테이징
    $add_output = shell_exec("cd $repo_path && git add . 2>&1");
    writeLog("Git Add 결과: $add_output");
    
    // 커밋
    $commit_output = shell_exec("cd $repo_path && git commit -m \"$commit_message\" 2>&1");
    writeLog("Git Commit 결과: $commit_output");
    
    // 푸시
    $push_output = shell_exec("cd $repo_path && git push origin $branch 2>&1");
    writeLog("Git Push 결과: $push_output");
    
    return $commit_output . "\n" . $push_output;
}

// 메인 감시 루프
writeLog("파일 감시 시작");
while (true) {
    try {
        if (checkGitStatus()) {
            writeLog("변경사항 감지됨");
            $result = gitCommitAndPush();
            writeLog("동기화 완료: $result");
        }
    } catch (Exception $e) {
        writeLog("에러 발생: " . $e->getMessage());
    }
    // 5초 대기 후 다시 체크
    sleep(5);
}
?>
