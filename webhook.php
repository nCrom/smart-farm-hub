
<?php
// 클라이언트와의 연결을 즉시 종료하고 백그라운드에서 처리하기 위한 설정
ignore_user_abort(true);
set_time_limit(0);
ob_start();

// GitHub에서 온 요청인지 검증
$github_signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';
$secret = "smart-farm-hub-secret"; // GitHub에서 설정할 시크릿키

// 요청 내용 가져오기
$payload = file_get_contents('php://input');

// 시그니처 검증
$hash = 'sha256=' . hash_hmac('sha256', $payload, $secret);
if (!hash_equals($github_signature, $hash)) {
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

// git pull 실행 (이제 백그라운드에서 실행됨)
shell_exec('git -C D:/nCrom_server/xampp8.2/htdocs pull > /dev/null 2>&1 &');
?>
