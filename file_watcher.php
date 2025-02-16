
<?php
/**
 * Git 자동 동기화 시스템
 * 로컬 변경사항을 자동으로 감지하여 GitHub 저장소와 동기화합니다.
 */

class GitWatcher {
    private $repoPath;
    private $githubToken;
    private $lockFile;
    private $logFile;
    private $lastHash;

    public function __construct() {
        $this->repoPath = __DIR__;
        $this->lockFile = 'git_watcher.lock';
        $this->logFile = 'git_watcher.log';
        $this->lastHash = null;
        
        // GitHub 토큰 확인
        $this->githubToken = getenv('GITHUB_TOKEN');
        if (!$this->githubToken) {
            $this->writeLog("오류: GitHub 토큰이 설정되지 않았습니다. 시스템 환경변수 GITHUB_TOKEN을 설정해주세요.");
            die();
        }
    }

    /**
     * 로그 기록
     */
    private function writeLog($message) {
        $timestamp = date('Y-m-d H:i:s');
        $logEntry = "[$timestamp] $message\n";
        file_put_contents($this->logFile, $logEntry, FILE_APPEND);
        echo $logEntry;
    }

    /**
     * 프로세스 잠금 관리
     */
    private function checkLock() {
        if (file_exists($this->lockFile)) {
            $pid = file_get_contents($this->lockFile);
            if (file_exists("/proc/$pid")) {
                $this->writeLog("경고: 다른 인스턴스가 이미 실행 중입니다 (PID: $pid)");
                die();
            }
        }
        file_put_contents($this->lockFile, getmypid());
    }

    /**
     * Git 명령어 실행
     */
    private function execGitCommand($command) {
        return shell_exec("cd {$this->repoPath} && $command 2>&1");
    }

    /**
     * 현재 Git 해시 가져오기
     */
    private function getCurrentHash() {
        return trim($this->execGitCommand('git rev-parse HEAD'));
    }

    /**
     * 변경사항 커밋 및 푸시
     */
    private function commitAndPush() {
        $timestamp = date('Y-m-d H:i:s');
        
        // 변경사항 스테이징
        $this->execGitCommand('git add .');
        
        // 커밋
        $this->execGitCommand(sprintf('git commit -m "자동 커밋: %s"', $timestamp));
        
        // GitHub로 푸시
        $pushResult = $this->execGitCommand('git push origin main');
        
        if (strpos($pushResult, 'error') === false) {
            $this->writeLog("성공: 변경사항이 GitHub에 동기화되었습니다.");
            return true;
        } else {
            $this->writeLog("오류: GitHub 푸시 실패 - $pushResult");
            return false;
        }
    }

    /**
     * 메인 감시 루프
     */
    public function watch() {
        $this->checkLock();
        
        // 종료 시 잠금 파일 삭제
        register_shutdown_function(function() {
            if (file_exists($this->lockFile)) {
                unlink($this->lockFile);
            }
        });

        $this->writeLog("정보: Git 파일 감시를 시작합니다");
        $this->writeLog("정보: 저장소 경로 - {$this->repoPath}");
        $this->writeLog("정보: GitHub 토큰 설정됨");

        while (true) {
            $currentHash = $this->getCurrentHash();
            
            if ($this->lastHash === null) {
                $this->lastHash = $currentHash;
            } elseif ($currentHash !== $this->lastHash) {
                $this->writeLog("정보: 변경사항이 감지되었습니다");
                
                if ($this->commitAndPush()) {
                    $this->lastHash = $currentHash;
                }
            }
            
            sleep(2);
        }
    }
}

// 실행
try {
    $watcher = new GitWatcher();
    $watcher->watch();
} catch (Exception $e) {
    echo "치명적 오류: " . $e->getMessage() . "\n";
    exit(1);
}
