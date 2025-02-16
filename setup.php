
<?php
// Git 사용자 설정
shell_exec('git config --global user.name "nCrom"');
shell_exec('git config --global user.email "realpano@naver.com"');

// GitHub 토큰 환경변수에서 읽기
$github_token = getenv('GITHUB_TOKEN');
if (!$github_token) {
    die("GitHub 토큰이 설정되지 않았습니다. 시스템 환경변수 GITHUB_TOKEN을 설정해주세요.\n");
}

// 저장소 경로
$repo_path = 'D:/nCrom_server/xampp8.2/htdocs';

// Git 저장소 확인 및 초기화
if (!is_dir("$repo_path/.git")) {
    echo "Git 저장소 초기화 중...\n";
    shell_exec("cd $repo_path && git init");
    
    // GitHub 토큰을 사용하여 원격 저장소 URL 설정
    $remote_url = "https://{$github_token}@github.com/nCrom/smart-farm-hub.git";
    shell_exec("cd $repo_path && git remote add origin {$remote_url}");
}

// 원격 저장소 URL 업데이트 (토큰 포함)
$remote_url = "https://{$github_token}@github.com/nCrom/smart-farm-hub.git";
shell_exec("cd $repo_path && git remote set-url origin {$remote_url}");

// Git 설정 확인
echo "Git 설정 확인 중...\n";
echo shell_exec("cd $repo_path && git config --list") . "\n";

// 원격 저장소 연결 테스트
echo "원격 저장소 연결 테스트 중...\n";
$test_result = shell_exec("cd $repo_path && git ls-remote 2>&1");
if (strpos($test_result, 'fatal') === false) {
    echo "원격 저장소 연결 성공!\n";
} else {
    echo "원격 저장소 연결 실패: $test_result\n";
}

echo "Git 설정이 완료되었습니다.\n";
echo "저장소 경로: $repo_path\n";
echo "원격 저장소가 설정되었습니다.\n";
?>
