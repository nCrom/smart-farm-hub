
<?php
// 파일 시스템 변경 감지 및 자동 Git 푸시 스크립트

// 환경 설정
$repo_path = 'D:/nCrom_server/xampp8.2/htdocs';
$branch = 'main';  // 또는 사용하는 브랜치명
$commit_message = '자동 커밋: 파일 시스템 변경 감지';

// Git 상태 확인
function checkGitStatus() {
    global $repo_path;
    $output = shell_exec("cd $repo_path && git status --porcelain");
    return !empty($output);
}

// Git 커밋 및 푸시
function gitCommitAndPush() {
    global $repo_path, $branch, $commit_message;
    $commands = array(
        "cd $repo_path",
        "git add .",
        "git commit -m \"$commit_message\"",
        "git push origin $branch"
    );
    
    $command = implode(" && ", $commands);
    shell_exec($command . " 2>&1");
}

// 메인 감시 루프
while (true) {
    if (checkGitStatus()) {
        gitCommitAndPush();
    }
    // 5초 대기 후 다시 체크
    sleep(5);
}
?>
