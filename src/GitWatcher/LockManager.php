
<?php
namespace GitWatcher;

class LockManager {
    public static function create() {
        if (file_exists(Config::$lock_file)) {
            return false;
        }
        file_put_contents(Config::$lock_file, getmypid());
        return true;
    }
    
    public static function release() {
        if (file_exists(Config::$lock_file)) {
            unlink(Config::$lock_file);
        }
    }
}
