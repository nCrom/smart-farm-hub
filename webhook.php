
<?php
// 로그 파일 설정
$log_file = 'webhook.log';

function writeLog($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
}

// GitHub 토큰 설정
$token = 'your_github_token_here'; // 여기에 GitHub 토큰을 입력하세요
file_put_contents('github_token.txt', $token);
writeLog("GitHub 토큰이 설정되었습니다.");

// GitHub API 설정
$github_token = file_exists('github_token.txt') ? trim(file_get_contents('github_token.txt')) : '';
$owner = 'nCrom';
$repo = 'smart-farm-hub';

// ngrok API를 통해 현재 터널 URL 가져오기
function getNgrokUrl() {
    $ngrok_api = "http://127.0.0.1:4040/api/tunnels";
    writeLog("ngrok API 요청: $ngrok_api");
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $ngrok_api);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    
    if (curl_errno($ch)) {
        writeLog("ngrok API 오류: " . curl_error($ch));
        curl_close($ch);
        return null;
    }
    
    curl_close($ch);
    writeLog("ngrok API 응답: " . $response);

    if ($response) {
        $tunnels = json_decode($response, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            writeLog("JSON 파싱 오류: " . json_last_error_msg());
            return null;
        }
        
        foreach ($tunnels['tunnels'] as $tunnel) {
            if ($tunnel['proto'] === 'https') {
                writeLog("ngrok URL 찾음: " . $tunnel['public_url']);
                return $tunnel['public_url'];
            }
        }
    }
    
    writeLog("ngrok URL을 찾을 수 없음");
    return null;
}

// GitHub Webhook URL 업데이트
function updateGithubWebhook($ngrok_url) {
    global $github_token, $owner, $repo;
    
    if (empty($github_token)) {
        writeLog("GitHub 토큰이 설정되지 않았습니다");
        return false;
    }
    
    // webhook ID를 저장할 파일
    $webhook_id_file = 'webhook_id.txt';
    
    // GitHub API 엔드포인트
    $api_url = "https://api.github.com/repos/$owner/$repo/hooks";
    
    // webhook 설정
    $webhook_data = array(
        'config' => array(
            'url' => $ngrok_url . '/webhook.php',
            'content_type' => 'application/json',
            'secret' => 'smart-farm-hub-secret',
            'insecure_ssl' => '0'
        ),
        'events' => ['push'],
        'active' => true
    );

    writeLog("webhook 데이터: " . json_encode($webhook_data));

    // 기존 webhook ID 확인
    $webhook_id = file_exists($webhook_id_file) ? file_get_contents($webhook_id_file) : null;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        'Accept: application/vnd.github.v3+json',
        'Authorization: token ' . $github_token,
        'User-Agent: PHP Script'
    ));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    if ($webhook_id) {
        // 기존 webhook 업데이트
        writeLog("기존 webhook 업데이트 (ID: $webhook_id)");
        curl_setopt($ch, CURLOPT_URL, "$api_url/$webhook_id");
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PATCH");
    } else {
        // 새 webhook 생성
        writeLog("새 webhook 생성");
        curl_setopt($ch, CURLOPT_URL, $api_url);
        curl_setopt($ch, CURLOPT_POST, true);
    }

    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($webhook_data));
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if (curl_errno($ch)) {
        writeLog("CURL 오류: " . curl_error($ch));
        curl_close($ch);
        return false;
    }
    
    curl_close($ch);
    writeLog("GitHub API 응답 코드: $http_code");
    writeLog("GitHub API 응답: $response");

    if ($http_code >= 200 && $http_code < 300) {
        $result = json_decode($response, true);
        if (!$webhook_id && isset($result['id'])) {
            // 새로 생성된 webhook ID 저장
            file_put_contents($webhook_id_file, $result['id']);
            writeLog("새 webhook ID 저장됨: " . $result['id']);
        }
        writeLog("Webhook URL 업데이트 성공: " . $ngrok_url);
        return true;
    }

    writeLog("Webhook URL 업데이트 실패: HTTP $http_code");
    return false;
}

// 스크립트 시작 시 ngrok URL 확인 및 업데이트
$ngrok_url = getNgrokUrl();
if ($ngrok_url) {
    writeLog("ngrok URL 발견: $ngrok_url");
    if (updateGithubWebhook($ngrok_url)) {
        writeLog("GitHub webhook 업데이트 완료");
    } else {
        writeLog("GitHub webhook 업데이트 실패");
    }
} else {
    writeLog("ngrok URL을 찾을 수 없음");
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
