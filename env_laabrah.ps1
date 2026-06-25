# env_laabrah.ps1
$DevToolsRoot = "C:\Users\yusf2000.runnervmo3n6x\.gemini\antigravity\scratch\yousfkarim2001"
$env:JAVA_HOME = "$DevToolsRoot\devtools\jdk"
$env:ANDROID_HOME = "$DevToolsRoot\devtools\android-sdk"
$env:PATH = "$DevToolsRoot\devtools\flutter\bin;$DevToolsRoot\devtools\android-sdk\platform-tools;$DevToolsRoot\devtools\jdk\bin;" + $env:PATH

if ($args.Count -gt 0) {
    & $args[0] $args[1..($args.Count-1)]
} else {
    echo "Environment set. Provide a command to run."
}
