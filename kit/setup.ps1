# deSPIRIA (dream-recomp) setup.
#
# Builds deSPIRIA as a native Windows program on this PC: it downloads dream-recomp's public source
# and a portable compiler, adds this kit's fixes and the deSPIRIA configuration, translates YOUR
# English-patched disc's program and compiles it. Nothing from the game is shipped in this kit.
#
# Run by deSPIRIA.exe when needed; safe to re-run. -Root is the app folder (the one with kit\).
# Your files and everything setup downloads (game\, saves\, tools\, build\) go in -Data, which
# deSPIRIA.exe sets to %LOCALAPPDATA%\deSPIRIA-DreamRecomp so app updates leave them alone.
param(
    [Parameter(Mandatory = $true)][string]$Root,
    [string]$Data,
    [string]$Disc,
    [switch]$Rebuild
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest crawls with a progress bar on PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = (Resolve-Path -LiteralPath $Root).Path
if (-not $Data) { $Data = $Root }
New-Item -ItemType Directory -Force -Path $Data | Out-Null
$Data = (Resolve-Path -LiteralPath $Data).Path
$KitVersion = (Get-Content -LiteralPath "$Root\kit\kit-version.txt" -Raw).Trim()   # not version.txt: Quiver owns that file

# Everything downloaded is pinned. Binaries must match their SHA-256; GitHub's source archives are
# pinned by commit and only warn on a different checksum, since GitHub may repack them.
$Pins = @{
    llvm   = @{ Url = 'https://github.com/mstorsjo/llvm-mingw/releases/download/20260616/llvm-mingw-20260616-ucrt-x86_64.zip'
                Sha = 'b9b68a4d276e16fa25802aaba458e4638f64b3884c290aaccdc2d87083b6ca35'; Dir = 'llvm-mingw' }
    cmake  = @{ Url = 'https://github.com/Kitware/CMake/releases/download/v3.31.12/cmake-3.31.12-windows-x86_64.zip'
                Sha = '0c4baa40f28b3f8225eb3fdf6946c987b4fe901403b4eaf2fbbd9378100aaa0c'; Dir = 'cmake' }
    ninja  = @{ Url = 'https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-win.zip'
                Sha = '07fc8261b42b20e71d1720b39068c2e14ffcee6396b76fb7a795fb460b78dc65'; Dir = 'ninja' }
    python = @{ Url = 'https://www.python.org/ftp/python/3.14.6/python-3.14.6-embed-amd64.zip'
                Sha = 'df901e84a896ff1ee720ad03377e0c8d8c2244fda79808aeeaff6316df1cb75c'; Dir = 'python' }
    sdl3   = @{ Url = 'https://github.com/libsdl-org/SDL/releases/download/release-3.4.18/SDL3-devel-3.4.18-mingw.zip'
                Sha = 'cd98158c8d025a816f430a600b4e9526524e6219ee884ec72bd498b80fd3bf58'; Dir = 'sdl3' }
    vkh    = @{ Url = 'https://codeload.github.com/KhronosGroup/Vulkan-Headers/zip/refs/tags/vulkan-sdk-1.4.363.0'
                Sha = 'f4be95220ff0ee0b1c620301ff4fe9ae48592d71f4c30f2d5c571351a153ae81'; Dir = 'vulkan-headers'; Source = $true }
    dream  = @{ Url = 'https://codeload.github.com/phobos665/dream-recomp/zip/51a148c7bf9191fa8593e707c4996cf887076b33'
                Sha = 'd707ef39cdfb2f423e1ba29d4e813607df16836fbfa6468b3dbd8459c3f7d507'; Dir = 'dream-recomp-src'; Source = $true }
    chdr   = @{ Url = 'https://codeload.github.com/rtissera/libchdr/zip/8e7b8bd32bc676b7e5c6b42fe7d2daca986c4a0d'
                Sha = 'd88f0ac2a338d78f33a7c7cbd705a4abd24ccddd6abf82151128812679555dc9'; Dir = 'libchdr-src'; Source = $true }
}
# The English Chapter 1 preview's boot program, one per battle-speed setting (from the patcher's
# own build metadata). Only these are accepted: the configuration is tuned to this program.
$KnownBoot = @{
    '39573c41c57505aabf4699ab4b391509ecfb1070e3e0b2ed1c44a8de05bb88bf' = 'English Chapter 1 preview, Original speed'
    'e38f6d07db3850b10e37f2e971e656beeb1faf2fb070106c6f8e7366b70e8fc3' = 'English Chapter 1 preview, Brisk speed'
    '7924e377af5704bffd0d27f3177ca3f6918a93debbca9dc76655f394a73b7334' = 'English Chapter 1 preview, Swift speed'
}

$kit   = "$Root\kit"
$tools = "$Data\tools"
$dl    = "$tools\downloads"
$build = "$Data\build"
$src   = "$build\dream-recomp"
$out   = "$build\out"
$game  = "$Data\game"
New-Item -ItemType Directory -Force -Path $tools, $dl, $build, $game, "$Data\saves" | Out-Null
Start-Transcript -LiteralPath "$Data\setup.log" -Force | Out-Null

function Step([string]$m) { Write-Host ''; Write-Host "== $m" -ForegroundColor Cyan }
# Native tools write progress to stderr; under 'Stop', PowerShell 5.1 would make that fatal.
function Native([scriptblock]$b) { $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'; try { & $b } finally { $ErrorActionPreference = $old } }
function Fail([string]$m) { Write-Host ''; Write-Host "SETUP FAILED: $m" -ForegroundColor Red; Stop-Transcript | Out-Null; exit 1 }

function Pick-File([string]$title, [string]$filter) {
    Add-Type -AssemblyName System.Windows.Forms
    $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true; ShowInTaskbar = $false }
    $dlg = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Title = $title; Filter = $filter }
    try { if ($dlg.ShowDialog($owner) -eq 'OK') { return $dlg.FileName } } finally { $owner.Dispose() }
    return $null
}

# Downloads one pinned zip, checks it and unpacks it into tools\<Dir> (once; a marker records the
# checksum, so a changed pin replaces it). Returns the folder the zip's single top folder became.
function Get-Pinned([string]$key) {
    $p = $Pins[$key]; $dest = "$tools\$($p.Dir)"; $marker = "$dest\.pinned"
    if ((Test-Path -LiteralPath $marker) -and (Get-Content -LiteralPath $marker -Raw).Trim() -eq $p.Sha) { return $dest }
    $zip = "$dl\$key.zip"
    Write-Host "Downloading $($p.Url.Split('/')[-1]) ..."
    Invoke-WebRequest $p.Url -OutFile $zip -UseBasicParsing
    $sha = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
    if ($sha -ne $p.Sha) {
        if (-not $p.Source) { Remove-Item -LiteralPath $zip; Fail "The download of $($p.Url) failed its checksum." }
        Write-Host "Note: GitHub repacked this source archive (checksum $sha); it is pinned by commit, continuing." -ForegroundColor Yellow
    }
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    $tmp = "$dl\$key.x"
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Native { & "$env:SystemRoot\System32\tar.exe" -xf $zip -C $tmp }
    if ($LASTEXITCODE -ne 0) { Fail "Could not unpack $zip." }
    $items = @(Get-ChildItem -LiteralPath $tmp -Force)
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) { Move-Item -LiteralPath $items[0].FullName -Destination $dest }
    else { Move-Item -LiteralPath $tmp -Destination $dest }
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    Remove-Item -LiteralPath $zip
    Set-Content -LiteralPath $marker -Value $p.Sha
    return $dest
}

# ---------------------------------------------------------------- disc
Step 'Disc reader (Python and the dream-recomp source)'
$python = "$(Get-Pinned 'python')\python.exe"
$dreamZip = Get-Pinned 'dream'
$dcdisc = "$dreamZip\tools\dcdisc"

Step 'Your deSPIRIA disc'
$toml = "$game\despiria_en.toml"
if (-not $Disc -and (Test-Path -LiteralPath $toml)) {
    $m = Select-String -LiteralPath $toml -Pattern '^image\s*=\s*"(.+)"'
    if ($m) { $existing = $m.Matches[0].Groups[1].Value -replace '/', '\'; if (Test-Path -LiteralPath $existing) { $Disc = $existing } }
}
if (-not $Disc) {
    Write-Host 'Choose the .gdi file of your English-patched deSPIRIA disc image.'
    Write-Host '(Patch your own Japanese disc first with the deSPIRIA Translation Initiative''s patcher; see README.)'
    $Disc = Pick-File 'Choose your English-patched deSPIRIA disc (.gdi)' 'GD-ROM image (*.gdi)|*.gdi'
    if (-not $Disc) { Fail 'No disc chosen.' }
}
$Disc = (Resolve-Path -LiteralPath $Disc).Path
New-Item -ItemType Directory -Force -Path "$game\extracted\fs" | Out-Null
$boot = "$game\extracted\fs\1ST_READ.BIN"
$info = Native { & $python -I "$kit\get_boot.py" $dcdisc $Disc $boot 2>&1 | ForEach-Object { "$_" } }
if ($LASTEXITCODE -ne 0) { Fail "Could not read that disc: $info" }
$fields = @{}; foreach ($kv in ("$info" -split '\s+')) { $k, $v = $kv -split '=', 2; if ($v) { $fields[$k] = $v } }
if ($fields.product -ne 'T14402M') { Fail "This disc is $($fields.product), not deSPIRIA (T14402M)." }
if (-not $KnownBoot.ContainsKey($fields.sha256)) {
    if ($fields.size -eq '1484260') { Fail 'This is the original Japanese disc. Apply the English patch to it first (see README), then choose the patched .gdi.' }
    Fail "This deSPIRIA disc's program is not one this kit knows (sha256 $($fields.sha256)). It supports the English Chapter 1 preview patch."
}
Write-Host "Disc: $Disc"
Write-Host "Found: $($KnownBoot[$fields.sha256])"
$discToml = $Disc -replace '\\', '/'
[IO.File]::WriteAllText($toml, (Get-Content -LiteralPath "$kit\game\despiria_en.toml.in" -Raw).Replace('@DISC@', $discToml),
    (New-Object Text.UTF8Encoding($false)))

$stamp = "$game\.kit-build"
$want = "$KitVersion $($fields.sha256)"
if (-not $Rebuild -and (Test-Path -LiteralPath "$game\despiria_en_boot.exe") -and (Test-Path -LiteralPath $stamp) -and
    (Get-Content -LiteralPath $stamp -Raw).Trim() -eq $want) {
    Step 'deSPIRIA is already built for this disc and kit version.'
    Stop-Transcript | Out-Null; exit 0
}

# ---------------------------------------------------------------- toolchain
Step 'Build tools (portable clang, CMake, Ninja, SDL3, Vulkan headers; about 1 GB, kept in tools\)'
$llvm  = Get-Pinned 'llvm'
$cmake = "$(Get-Pinned 'cmake')\bin\cmake.exe"
$ninja = "$(Get-Pinned 'ninja')\ninja.exe"
$sdl3  = Get-Pinned 'sdl3'
$vkh   = Get-Pinned 'vkh'
$chdr  = Get-Pinned 'chdr'
foreach ($f in "$llvm\bin\clang++.exe", $cmake, $ninja, "$sdl3\x86_64-w64-mingw32\lib\cmake\SDL3\SDL3Config.cmake", "$vkh\include\vulkan\vulkan.h") {
    if (-not (Test-Path -LiteralPath $f)) { Fail "The build tools are incomplete: $f is missing." }
}
# The Vulkan import library, made from the export list in the kit: the loader itself
# (vulkan-1.dll) comes with every graphics driver, so the Vulkan SDK is not needed.
$vkLib = "$tools\vulkan-lib\libvulkan-1.dll.a"
New-Item -ItemType Directory -Force -Path "$tools\vulkan-lib" | Out-Null
Native { & "$llvm\bin\llvm-dlltool.exe" -m i386:x86-64 -d "$kit\vulkan-1.def" -l $vkLib }
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $vkLib)) { Fail 'Could not make the Vulkan import library.' }

# ---------------------------------------------------------------- source
Step 'dream-recomp source (51a148c, github.com/phobos665/dream-recomp) with this kit''s fixes'
if (Test-Path -LiteralPath $src) { Remove-Item -LiteralPath $src -Recurse -Force }
Copy-Item -LiteralPath $dreamZip -Destination $src -Recurse
Remove-Item -LiteralPath "$src\.pinned" -ErrorAction SilentlyContinue
$chdrDst = "$src\third_party\libchdr"
if (Test-Path -LiteralPath $chdrDst) { Remove-Item -LiteralPath $chdrDst -Recurse -Force }
Copy-Item -LiteralPath $chdr -Destination $chdrDst -Recurse
# robocopy merges into existing folders (Copy-Item -Recurse can nest them); 0-7 mean success.
Native { & robocopy.exe "$kit\overlay" $src /E /NFL /NDL /NJH /NJS /NP | Out-Null }
if ($LASTEXITCODE -ge 8) { Fail 'Could not add the kit''s fixes to the source.' }
$gsrc = "$src\games\despiria_en"
New-Item -ItemType Directory -Force -Path "$gsrc\extracted\fs" | Out-Null
Copy-Item -LiteralPath "$kit\game\CMakeLists.txt" -Destination $gsrc
Copy-Item -LiteralPath $toml -Destination "$gsrc\despiria_en.toml"
Copy-Item -LiteralPath $boot -Destination "$gsrc\extracted\fs\1ST_READ.BIN"

# ---------------------------------------------------------------- build
Step 'Translating and compiling deSPIRIA (about 5 to 15 minutes)'
$env:PATH = "$llvm\bin;$(Split-Path -Parent $cmake);$(Split-Path -Parent $ninja);$env:PATH"
if ($Rebuild -and (Test-Path -LiteralPath $out)) { Remove-Item -LiteralPath $out -Recurse -Force }
$cfg = @('-S', $src, '-B', $out, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=Release',
    "-DCMAKE_MAKE_PROGRAM=$ninja", "-DCMAKE_C_COMPILER=$llvm\bin\clang.exe", "-DCMAKE_CXX_COMPILER=$llvm\bin\clang++.exe",
    '-DDREAM_DEV_INTERPRETER=ON',   # the configuration leaves three functions to the interpreter
    '-DDREAM_WERROR=OFF', '-DDREAM_BUILD_TESTS=OFF',
    "-DSDL3_DIR=$sdl3\x86_64-w64-mingw32\lib\cmake\SDL3",
    "-DVulkan_INCLUDE_DIR=$vkh\include", "-DVulkan_LIBRARY=$vkLib",
    "-DPython3_EXECUTABLE=$python")
Native { & $cmake @cfg 2>&1 | ForEach-Object { "$_" } | Select-String -Pattern 'dream::|error|Error' | ForEach-Object { "$_" } }
if ($LASTEXITCODE -ne 0) { Fail "CMake could not configure the build. See $Data\setup.log." }
Native { & $cmake --build $out --target despiria_en_boot 2>&1 | ForEach-Object { "$_" } | Select-String -Pattern 'Translating|coverage|error:|FAILED|Linking CXX executable' | ForEach-Object { "$_" } }
$exe = "$out\games\despiria_en\despiria_en_boot.exe"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exe)) { Fail "deSPIRIA did not build. See $Data\setup.log." }

# ---------------------------------------------------------------- install
Step 'Installing'
Copy-Item -LiteralPath $exe -Destination $game -Force
Copy-Item -LiteralPath "$out\games\despiria_en\SDL3.dll" -Destination $game -Force
foreach ($dll in 'libc++.dll', 'libunwind.dll') { Copy-Item -LiteralPath "$llvm\bin\$dll" -Destination $game -Force }
Set-Content -LiteralPath $stamp -Value $want
Write-Host ''
Write-Host 'Setup complete. Starting deSPIRIA...' -ForegroundColor Green
Stop-Transcript | Out-Null
exit 0
