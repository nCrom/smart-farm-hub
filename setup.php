
<?php
// Git 사용자 설정
shell_exec('git config --global user.name "nCrom"');
shell_exec('git config --global user.email "realpano@naver.com"');

// 저장소 경로
$repo_path = 'D:/nCrom_server/xampp8.2/htdocs';

// Git 저장소 확인 및 초기화
if (!is_dir("$repo_path/.git")) {
    echo "Git 저장소 초기화 중...\n";
    shell_exec("cd $repo_path && git init");
    shell_exec("cd $repo_path && git remote add origin https://github.com/nCrom/smart-farm-hub.git");
}

// 원격 저장소 URL 설정 확인/업데이트
$remote_url = shell_exec("cd $repo_path && git remote get-url origin 2>&1");
if (strpos($remote_url, 'smart-farm-hub') === false) {
    shell_exec("cd $repo_path && git remote set-url origin https://github.com/nCrom/smart-farm-hub.git");
}

echo "Git 설정이 완료되었습니다.\n";
echo "저장소 경로: $repo_path\n";
echo "원격 저장소: " . shell_exec("cd $repo_path && git remote -v") . "\n";
?>
