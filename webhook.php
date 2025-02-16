
<?php
// 로그 파일 설정
$log_file = 'webhook.log';

function writeLog($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
}

// 클라이언트와의 연결을 즉시 종료하고 백그라운드에서 처리
ignore_user_abort(true);
set_time_limit(0);
ob_start();

// GitHub에서 온 요청인지 검증
$github_signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';
$secret = "smart-farm-hub-secret";
$payload = file_get_contents('php://input');

// 시그니처 검증
$hash = 'sha256=' . hash_hmac('sha256', $payload, $secret);
if (!hash_equals($github_signature, $hash)) {
    writeLog("인증 실패");
    http_response_code(403);
    exit('인증 실패');
}

// 즉시 응답 반환
header('Content-Length: ' . ob_get_length());
header('Connection: close');
ob_end_flush();
flush();

// 백그라운드에서 git pull 실행
if (function_exists('fastcgi_finish_request')) {
    fastcgi_finish_request();
}

writeLog("Webhook 수신됨");

// git pull 실행
$output = shell_exec('git -C D:/nCrom_server/xampp8.2/htdocs pull 2>&1');
writeLog("Git Pull 결과: " . $output);

// 캐시 삭제 등 추가 작업
shell_exec('php -r "opcache_reset();" 2>&1');
writeLog("캐시 초기화 완료");
?>
