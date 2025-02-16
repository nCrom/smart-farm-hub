
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

// Lock 파일 경로 설정
function getLockFilePath() {
    return sys_get_temp_dir() . '/git_sync.lock';
}

// Lock 파일 관리
function createLock() {
    $lock_file = getLockFilePath();
    if (file_exists($lock_file)) {
        $lock_time = filemtime($lock_file);
        // 10초 후 자동 해제 (더 짧게 조정)
        if (time() - $lock_time > 10) {
            @unlink($lock_file);
        } else {
            return false;
        }
    }
    file_put_contents($lock_file, date('Y-m-d H:i:s'));
    return true;
}

function releaseLock() {
    $lock_file = getLockFilePath();
    if (file_exists($lock_file)) {
        @unlink($lock_file);
    }
}

// Git 상태 확인
function checkGitStatus() {
    global $repo_path;
    
    writeLog("Git 상태 확인 시작...");
    
    if (!createLock()) {
        writeLog("Lock 파일이 존재하여 건너뜀");
        return false;
    }
    
    // GitHub 토큰 확인
    $github_token = getenv('GITHUB_TOKEN');
    if (!$github_token) {
        writeLog("경고: GitHub 토큰이 설정되지 않음");
        releaseLock();
        return false;
    }
    
    $output = shell_exec("cd $repo_path && git status --porcelain");
    writeLog("Git status 결과: " . ($output ? $output : "변경사항 없음"));
    
    if (empty($output)) {
        releaseLock();
        return false;
    }
    
    $excluded_files = ['git_sync.log', 'webhook.log', '.git'];
    $changes = array_filter(
        explode("\n", trim($output)),
        function($line) use ($excluded_files) {
            if (empty($line)) return false;
            foreach ($excluded_files as $excluded) {
                if (strpos($line, $excluded) !== false) {
                    return false;
                }
            }
            return true;
        }
    );
    
    if (empty($changes)) {
        writeLog("제외된 파일을 제외하고 변경사항 없음");
        releaseLock();
        return false;
    }
    
    writeLog("변경사항 감지됨: " . count($changes) . "개 파일");
    foreach ($changes as $change) {
        writeLog("변경된 파일: " . trim($change));
    }
    return true;
}

// Git 커밋 및 푸시
function gitCommitAndPush() {
    global $repo_path, $branch, $commit_message;
    
    try {
        // GitHub 토큰으로 원격 저장소 URL 업데이트
        $github_token = getenv('GITHUB_TOKEN');
        $remote_url = "https://{$github_token}@github.com/nCrom/smart-farm-hub.git";
        shell_exec("cd $repo_path && git remote set-url origin {$remote_url}");
        writeLog("원격 저장소 URL 업데이트됨");
        
        // 변경사항 스테이징
        $add_output = shell_exec("cd $repo_path && git add -A 2>&1");
        writeLog("Git Add 결과: " . trim($add_output));
        
        // 커밋 전 상태 확인
        $status_output = shell_exec("cd $repo_path && git status 2>&1");
        writeLog("커밋 전 상태: " . trim($status_output));
        
        // 커밋
        $commit_output = shell_exec("cd $repo_path && git commit -m \"$commit_message\" 2>&1");
        writeLog("Git Commit 결과: " . trim($commit_output));
        
        // 푸시 전 원격 저장소 상태 확인
        $remote_status = shell_exec("cd $repo_path && git remote -v 2>&1");
        writeLog("원격 저장소 상태: " . trim($remote_status));
        
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
writeLog("저장소 경로: " . $repo_path);
writeLog("GitHub 토큰 설정 상태: " . (getenv('GITHUB_TOKEN') ? "설정됨" : "설정되지 않음"));

// 시작 시 lock 파일 정리
releaseLock();

while (true) {
    try {
        if (checkGitStatus()) {
            writeLog("변경사항 감지됨 - 커밋 및 푸시 시도");
            if (gitCommitAndPush()) {
                writeLog("동기화 완료");
            } else {
                writeLog("동기화 실패");
            }
        }
    } catch (Exception $e) {
        writeLog("예외 발생: " . $e->getMessage());
        releaseLock();
    }
    
    // 로그 파일 크기 관리 (1MB 초과시 초기화)
    if (file_exists($log_file) && filesize($log_file) > 1000000) {
        file_put_contents($log_file, '');
        writeLog("로그 파일 초기화됨");
    }
    
    sleep(2); // 체크 주기를 2초로 단축
}
?>
