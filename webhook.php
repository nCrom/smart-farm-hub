<?php
// 로그 파일 설정
$log_file = 'webhook_log.txt';

// GitHub에서 온 요청인지 검증
$github_signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';
$secret = "smart-farm-hub-secret"; // GitHub에서 설정할 시크릿키

// 요청 내용 가져오기
$payload = file_get_contents('php://input');

// 시그니처 검증
$hash = 'sha256=' . hash_hmac('sha256', $payload, $secret);
if (!hash_equals($github_signature, $hash)) {
    file_put_contents($log_file, date('Y-m-d H:i:s') . " - 인증 실패\n", FILE_APPEND);
    exit('인증 실패');
}

// git pull 실행
$output = shell_exec('git -C D:/nCrom_server/xampp8.2/htdocs pull 2>&1');

// 로그 기록
$log_message = date('Y-m-d H:i:s') . " - Git Pull 실행됨: " . $output;
file_put_contents($log_file, $log_message . "\n", FILE_APPEND);

echo "성공적으로 업데이트됨: " . $output;
?>
