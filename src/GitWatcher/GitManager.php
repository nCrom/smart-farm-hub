
<?php
namespace GitWatcher;

class GitManager {
    private static function cleanOutput($output) {
        return preg_replace('/Active code page: \d+\n?/', '', trim($output));
    }
    
    public static function checkStatus() {
        Logger::log("Git 상태 확인 시작...");
        
        if (!LockManager::create()) {
            Logger::log("Lock 파일이 존재하여 건너뜀");
            return false;
        }
        
        $lock_file = Config::$repo_path . "/.git/index.lock";
        if (file_exists($lock_file)) {
            @unlink($lock_file);
            Logger::log("Git index.lock 파일 제거됨");
        }
        
        $github_token = getenv('GITHUB_TOKEN');
        if (!$github_token) {
            Logger::log("경고: GitHub 토큰이 설정되지 않음");
            LockManager::release();
            return false;
        }
        
        $remote_url = "https://{$github_token}@github.com/nCrom/smart-farm-hub.git";
        shell_exec("cd " . Config::$repo_path . " && git remote set-url origin {$remote_url} 2>&1");
        
        shell_exec("cd " . Config::$repo_path . " && git reset --hard HEAD && git clean -f -d 2>&1");
        shell_exec("cd " . Config::$repo_path . " && git fetch origin && git reset --hard origin/main 2>&1");
        Logger::log("로컬 브랜치를 원격과 동기화함");
        
        $push_output = shell_exec("cd " . Config::$repo_path . " && git push -f origin main 2>&1");
        Logger::log("Git Push 결과: " . self::cleanOutput($push_output));
        
        $output = shell_exec("cd " . Config::$repo_path . " && git status --porcelain 2>&1");
        $output = self::cleanOutput($output);
        
        if (empty($output)) {
            LockManager::release();
            return false;
        }
        
        $changes = self::getFilteredChanges($output);
        
        if (empty($changes)) {
            Logger::log("제외된 파일을 제외하고 변경사항 없음");
            LockManager::release();
            return false;
        }
        
        Logger::log("변경사항 감지됨: " . count($changes) . "개 파일");
        foreach ($changes as $change) {
            Logger::log("변경된 파일: " . trim($change));
        }
        return true;
    }
    
    private static function getFilteredChanges($output) {
        return array_filter(
            explode("\n", $output),
            function($line) {
                $line = trim($line);
                if (empty($line)) return false;
                foreach (Config::$excluded_files as $excluded) {
                    if (strpos($line, $excluded) !== false) {
                        return false;
                    }
                }
                return true;
            }
        );
    }
    
    public static function commitAndPush() {
        try {
            $github_token = getenv('GITHUB_TOKEN');
            $remote_url = "https://{$github_token}@github.com/nCrom/smart-farm-hub.git";
            shell_exec("cd " . Config::$repo_path . " && git remote set-url origin {$remote_url} 2>&1");
            Logger::log("원격 저장소 URL 업데이트됨");
            
            $add_output = shell_exec("cd " . Config::$repo_path . " && git add -A 2>&1");
            Logger::log("Git Add 결과: " . self::cleanOutput($add_output));
            
            $status_output = shell_exec("cd " . Config::$repo_path . " && git status 2>&1");
            
            if (strpos($status_output, "nothing to commit") === false) {
                $commit_output = shell_exec("cd " . Config::$repo_path . " && git commit -m \"" . Config::$commit_message . "\" 2>&1");
                Logger::log("Git Commit 결과: " . self::cleanOutput($commit_output));
                
                $push_output = shell_exec("cd " . Config::$repo_path . " && git push -f origin " . Config::$branch . " 2>&1");
                Logger::log("Git Push 결과: " . self::cleanOutput($push_output));
            } else {
                Logger::log("커밋할 변경사항 없음");
            }
            
            LockManager::release();
            return true;
        } catch (\Exception $e) {
            Logger::log("에러 발생: " . $e->getMessage());
            LockManager::release();
            return false;
        }
    }
}
