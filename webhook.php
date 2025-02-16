<?php
$secret = "smart-farm-hub-secret";

$github_signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';
$payload = file_get_contents('php://input');
$hash = 'sha256=' . hash_hmac('sha256', $payload, $secret);

if (!hash_equals($github_signature, $hash)) {
    exit('인증 실패');
}

$output = shell_exec('git -C D:/nCrom_server/xampp8.2/htdocs pull 2>&1');
echo $output;
?>
