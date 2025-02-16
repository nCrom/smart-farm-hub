
<?php
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

// git pull 실행
$output = shell_exec('git -C D:/nCrom_server/xampp8.2/htdocs pull 2>&1');

echo "성공적으로 업데이트됨: " . $output;
?>

