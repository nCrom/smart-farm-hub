
<?php
// 로그 기록 함수
function writeLog($message) {
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[$timestamp] $message\n";
    file_put_contents('git_watcher.log', $log_entry, FILE_APPEND);
    echo $log_entry;
}

// 잠금 파일 확인
$lock_file = 'git_watcher.lock';
if (file_exists($lock_file)) {
    $pid = file_get_contents($lock_file);
    if (file_exists("/proc/$pid")) {
        writeLog("다른 인스턴스가 이미 실행 중입니다");
        die();
    }
}
file_put_contents($lock_file, getmypid());

// 종료 시 잠금 파일 삭제
register_shutdown_function(function() use ($lock_file) {
    if (file_exists($lock_file)) {
        unlink($lock_file);
    }
});

// GitHub 토큰 확인
$github_token = getenv('GITHUB_TOKEN');
if (!$github_token) {
    writeLog("GitHub 토큰이 설정되지 않았습니다");
    die();
}

// 저장소 경로 설정
$repo_path = __DIR__;
$last_hash = null;

writeLog("파일 감시 시작");
writeLog("저장소 경로: $repo_path");
writeLog("GitHub 토큰 설정 상태: " . ($github_token ? "설정됨" : "설정되지 않음"));

// 메인 루프
while (true) {
    // 현재 커밋 해시 확인
    $current_hash = trim(shell_exec("cd $repo_path && git rev-parse HEAD"));
    
    // 초기 실행이거나 변경사항이 있는 경우
    if ($last_hash === null) {
        $last_hash = $current_hash;
    } elseif ($current_hash !== $last_hash) {
        writeLog("변경사항 감지됨 - 커밋 및 푸시 시도");
        
        // 변경사항 커밋 및 푸시
        shell_exec("cd $repo_path && git add .");
        $timestamp = date('Y-m-d H:i:s');
        shell_exec("cd $repo_path && git commit -m \"자동 커밋: $timestamp\"");
        $push_result = shell_exec("cd $repo_path && git push origin main 2>&1");
        
        if (strpos($push_result, 'error') === false) {
            writeLog("동기화 완료");
            $last_hash = $current_hash;
        } else {
            writeLog("푸시 오류: $push_result");
        }
    }
    
    sleep(2);
}
