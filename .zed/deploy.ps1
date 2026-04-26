$sourceRoot = Split-Path $PSScriptRoot -Parent
$modName = Split-Path $sourceRoot -Leaf
$source = "$sourceRoot\Contents\mods\$modName"
$target = "C:\Users\$env:USERNAME\Zomboid\mods\"

if (Test-Path $target\$modName) {
    Remove-Item -LiteralPath $target\$modName -Recurse -Force
}

New-Item -ItemType Directory -Path $target -Force
robocopy $source $target\$modName /E /XD ".git" ".zed" /XF "LICENSE" "README.md"
