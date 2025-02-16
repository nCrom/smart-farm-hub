
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

// Lock 파일 관리 함수들
function createLock() {
    $lock_file = 'git.lock';
    if (file_exists($lock_file)) {
        $lock_time = filemtime($lock_file);
        // 5분 이상 된 lock 파일은 제거
        if (time() - $lock_time > 300) {
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
    }
}

// Git 작업이 실행 중인지 확인
function isGitBusy() {
    global $repo_path;
    return file_exists("$repo_path/.git/index.lock") || 
           file_exists("$repo_path/.git/HEAD.lock") || 
           !createLock();
}

// Git 상태 확인
function checkGitStatus() {
    global $repo_path;
    if (isGitBusy()) {
        writeLog("다른 Git 작업이 실행 중입니다. 대기 중...");
        return false;
    }
    
    $excluded_files = array(
        'git_sync.log',
        'webhook.log',
        'aaaa.txt',
        'aaaa - 복사본.txt'
    );
    
    $output = shell_exec("cd $repo_path && git status --porcelain");
    if (empty($output)) {
        return false;
    }
    
    // 제외할 파일들을 필터링
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
    
    writeLog("Git 상태 확인: " . (!empty($changes) ? "변경사항 있음" : "변경사항 없음"));
    return !empty($changes);
}

// Git 풀 수행
function gitPull() {
    global $repo_path;
    if (isGitBusy()) {
        writeLog("Git Pull 실패: 다른 Git 작업이 실행 중입니다");
        return false;
    }
    
    writeLog("Git Pull 시작");
    $pull_output = shell_exec("cd $repo_path && git pull origin main 2>&1");
    writeLog("Git Pull 결과: $pull_output");
    
    return true;
}

// Git 커밋 및 푸시
function gitCommitAndPush() {
    global $repo_path, $branch, $commit_message;
    
    if (isGitBusy()) {
        writeLog("Git 작업 실패: 다른 Git 작업이 실행 중입니다");
        return false;
    }
    
    try {
        // 현재 브랜치 확인
        $current_branch = trim(shell_exec("cd $repo_path && git rev-parse --abbrev-ref HEAD"));
        writeLog("현재 브랜치: $current_branch");
        
        if ($current_branch !== $branch) {
            writeLog("브랜치 전환: $branch");
            shell_exec("cd $repo_path && git checkout $branch");
        }
        
        // 변경사항 스테이징
        $add_output = shell_exec("cd $repo_path && git add -A 2>&1");
        writeLog("Git Add 결과: $add_output");
        
        // 커밋 전에 변경사항이 있는지 다시 확인
        if (!checkGitStatus()) {
            writeLog("커밋할 변경사항이 없습니다");
            releaseLock();
            return true;
        }
        
        // 커밋
        $commit_output = shell_exec("cd $repo_path && git commit -m \"$commit_message\" 2>&1");
        writeLog("Git Commit 결과: $commit_output");
        
        // 푸시
        $push_output = shell_exec("cd $repo_path && git push origin $branch 2>&1");
        writeLog("Git Push 결과: $push_output");
        
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
while (true) {
    try {
        if (checkGitStatus() && !isGitBusy()) {
            writeLog("변경사항 감지됨");
            if (gitCommitAndPush()) {
                writeLog("동기화 완료");
            } else {
                writeLog("동기화 실패: Git 작업이 실행 중입니다");
            }
        }
    } catch (Exception $e) {
        writeLog("에러 발생: " . $e->getMessage());
    }
    
    // 로그 파일 크기 관리
    if (file_exists($log_file) && filesize($log_file) > 1000000) { // 1MB 이상이면
        file_put_contents($log_file, ''); // 로그 파일 초기화
    }
    
    // 5초 대기 후 다시 체크
    sleep(5);
}
?>
