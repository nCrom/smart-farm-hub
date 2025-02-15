
# PowerShell script encoding settings
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

# Git environment variables
$env:LANG = "en_US.UTF-8"
$env:LC_ALL = "en_US.UTF-8"
$env:GIT_COMMITTER_ENCODING = "UTF-8"
$env:GIT_AUTHOR_ENCODING = "UTF-8"

# Repository path
$repoPath = "D:\nCrom_server\xampp8.2\htdocs"
Set-Location $repoPath

# Git global settings
git config --global core.quotepath off
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global core.precomposeunicode true

# Log file settings
$logFile = "git-sync.log"

while ($true) {
    try {
        # Initialize Git repository status
        git reset --hard HEAD
        git clean -fd
        git pull origin main --quiet
        
        # Check for changes (limit output)
        $status = git -c advice.statusHints=false status --porcelain
        if ($status) {
            # Stage all changes
            git add .
            
            # Create commit with current timestamp
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $commitMessage = "[Auto] Changes detected at $timestamp"
            
            # Execute commit (using UTF-8)
            $env:GIT_COMMITTER_NAME = "Auto Commit"
            $env:GIT_COMMITTER_EMAIL = "auto@commit.local"
            $env:GIT_AUTHOR_NAME = "Auto Commit"
            $env:GIT_AUTHOR_EMAIL = "auto@commit.local"
            
            git -c i18n.commitencoding=utf-8 commit -m $commitMessage | Out-Null
            
            # Push to GitHub (limit output)
            git -c advice.statusHints=false push origin main --force --quiet
            
            # Write to log file
            $message = "====================`n"
            $message += "Time: $timestamp`n"
            $message += "Status: Success`n"
            $message += "Message: $commitMessage`n"
            $message += "====================`n"
            [System.IO.File]::WriteAllText($logFile, $message, [System.Text.Encoding]::UTF8)
            
            # Console output
            Write-Output "`n-------------------"
            Write-Output "Time: $timestamp"
            Write-Output "Status: Success"
            Write-Output "Message: $commitMessage"
            Write-Output "-------------------`n"
        }
        
        # Wait 30 seconds
        Start-Sleep -Seconds 30
    }
    catch {
        $errorMsg = "====================`n"
        $errorMsg += "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $errorMsg += "Status: Error`n"
        $errorMsg += "Message: $_`n"
        $errorMsg += "====================`n"
        
        # Write error to log file
        [System.IO.File]::WriteAllText($logFile, $errorMsg, [System.Text.Encoding]::UTF8)
        
        # Console output
        Write-Output "`n-------------------"
        Write-Output "Status: Error"
        Write-Output "Message: $_"
        Write-Output "-------------------`n"
        
        Start-Sleep -Seconds 10
    }
}
