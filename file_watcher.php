
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

// Lock 파일 강제 제거
function forceClearLocks() {
    global $repo_path;
    $lockFiles = [
        "$repo_path/.git/index.lock",
        "$repo_path/.git/HEAD.lock",
        'git.lock'
    ];
    
    foreach ($lockFiles as $lockFile) {
        if (file_exists($lockFile)) {
            unlink($lockFile);
            writeLog("Lock 파일 제거: $lockFile");
        }
    }
}

// Lock 파일 관리
function createLock() {
    $lock_file = 'git.lock';
    if (file_exists($lock_file)) {
        $lock_time = filemtime($lock_file);
        if (time() - $lock_time > 60) { // 1분 후 자동 해제
            unlink($lock_file);
        } else {
            return false;
        }
    }
    file_put_contents($lock_file, date('Y-m-d H:i:s'));
    return true;
}

function releaseLock() {
    $lock_file = 'git.lock';
    if (file_exists($lock_file)) {
        unlink($lock_file);
        writeLog("Lock 파일 해제됨");
    }
}

// Git 작업이 실행 중인지 확인
function isGitBusy() {
    global $repo_path;
    
    // 오래된 lock 파일 정리
    if (rand(1, 10) === 1) { // 10% 확률로 실행
        forceClearLocks();
    }
    
    return !createLock();
}

// Git 상태 확인
function checkGitStatus() {
    global $repo_path;
    
    if (isGitBusy()) {
        writeLog("다른 Git 작업이 실행 중입니다. 대기 중...");
        return false;
    }
    
    $output = shell_exec("cd $repo_path && git status --porcelain");
    if (empty($output)) {
        releaseLock();
        return false;
    }
    
    $excluded_files = ['git_sync.log', 'webhook.log', 'git.lock'];
    $changes = array_filter(
        explode("\n", trim($output)),
        function($line) use ($excluded_files) {
            foreach ($excluded_files as $excluded) {
                if (strpos($line, $excluded) !== false) {
                    return false;
                }
            }
            return !empty($line);
        }
    );
    
    if (empty($changes)) {
        releaseLock();
        return false;
    }
    
    writeLog("변경사항 감지됨: " . count($changes) . "개 파일");
    return true;
}

// Git 커밋 및 푸시
function gitCommitAndPush() {
    global $repo_path, $branch, $commit_message;
    
    try {
        // 변경사항 스테이징
        $add_output = shell_exec("cd $repo_path && git add -A 2>&1");
        writeLog("Git Add 결과: " . trim($add_output));
        
        // 커밋
        $commit_output = shell_exec("cd $repo_path && git commit -m \"$commit_message\" 2>&1");
        writeLog("Git Commit 결과: " . trim($commit_output));
        
        // 푸시
        $push_output = shell_exec("cd $repo_path && git push origin $branch 2>&1");
        writeLog("Git Push 결과: " . trim($push_output));
        
        releaseLock();
        return true;
    } catch (Exception $e) {
        writeLog("에러 발생: " . $e->getMessage());
        releaseLock();
        return false;
    }
}

// 메인 감시 루프
writeLog("파일 감시 시작");
forceClearLocks(); // 시작 시 lock 파일 정리

while (true) {
    try {
        if (checkGitStatus()) {
            if (gitCommitAndPush()) {
                writeLog("동기화 완료");
            } else {
                writeLog("동기화 실패");
            }
        }
    } catch (Exception $e) {
        writeLog("에러 발생: " . $e->getMessage());
        releaseLock();
    }
    
    // 로그 파일 크기 관리 (1MB 초과시 초기화)
    if (file_exists($log_file) && filesize($log_file) > 1000000) {
        file_put_contents($log_file, '');
        writeLog("로그 파일 초기화됨");
    }
    
    sleep(5);
}
?>
