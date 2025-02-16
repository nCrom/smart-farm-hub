
<?php
// 로그 파일 설정
$log_file = 'webhook.log';

function writeLog($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
}

// webhook 요청 처리
writeLog("Webhook 요청 수신");
writeLog("요청 메소드: " . $_SERVER['REQUEST_METHOD']);

// POST 요청인지 확인
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    writeLog("잘못된 요청 메소드: " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    die('Method Not Allowed');
}

// GitHub 시크릿 설정 - 환경 변수에서 읽기
$secret = getenv('GITHUB_WEBHOOK_SECRET');
if (!$secret) {
    writeLog("GitHub Webhook Secret이 설정되지 않았습니다");
    http_response_code(500);
    die('Configuration Error');
}

// GitHub에서 온 요청인지 검증
$headers = getallheaders();
$signature = $headers['X-Hub-Signature-256'] ?? '';

if (empty($signature)) {
    writeLog("서명이 없음");
    http_response_code(401);
    die('No Signature');
}

// 페이로드 가져오기
$payload = file_get_contents('php://input');
writeLog("수신된 페이로드 크기: " . strlen($payload) . " bytes");

// 시그니처 검증
$hash = 'sha256=' . hash_hmac('sha256', $payload, $secret);
if (!hash_equals($signature, $hash)) {
    writeLog("잘못된 서명");
    http_response_code(403);
    die('Invalid Signature');
}

// 클라이언트와의 연결을 즉시 종료하고 백그라운드에서 처리
ignore_user_abort(true);
set_time_limit(0);

// 성공 응답 전송
http_response_code(200);
writeLog("검증 성공, 200 응답 전송");

// Git 작업 수행
$repo_path = 'D:/nCrom_server/xampp8.2/htdocs';
writeLog("Git pull 시작: " . $repo_path);

// git pull 실행
$output = shell_exec("cd $repo_path && git pull origin main 2>&1");
writeLog("Git pull 결과: " . $output);

// 캐시 초기화
shell_exec('php -r "opcache_reset();" 2>&1');
writeLog("캐시 초기화 완료");

die('OK');
?>
