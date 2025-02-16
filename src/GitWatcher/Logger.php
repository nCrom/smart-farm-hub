
<?php
namespace GitWatcher;

class Logger {
    public static function log($message) {
        $timestamp = date('Y-m-d H:i:s');
        $log_entry = "[$timestamp] $message\n";
        file_put_contents(Config::$log_file, $log_entry, FILE_APPEND);
        echo $log_entry;
    }
}
