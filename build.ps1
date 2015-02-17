# This script will clone and build the latest Chrome v8 sources. Make sure you
# have Git and Python in your path.

$PACKAGES_DIRECTORY = Join-Path $PSScriptRoot "packages"
$OUTPUT_DIRECTORY   = Join-Path $PSScriptRoot "bin"
$VERSION            = "0.0.0"

if (Test-Path Env:\APPVEYOR_BUILD_VERSION) {
    $VERSION = $env:APPVEYOR_BUILD_VERSION
}

# Nuget configuration section
$NUGET_FILE         = "nuget.exe"
$NUGET_TOOL         = Join-Path $PACKAGES_DIRECTORY $NUGET_FILE
$NUGET_DOWNLOAD_URL = "https://nuget.org/$NUGET_FILE"

$V8_DIRECTORY  = Join-Path $PACKAGES_DIRECTORY "v8"
$V8_REPOSITORY = "https://chromium.googlesource.com/v8/v8.git"

$GYP_DIRECTORY  = Join-Path $V8_DIRECTORY "build/gyp"
$GYP_REPOSITORY = "https://chromium.googlesource.com/external/gyp.git"

$ICU_DIRECTORY  = Join-Path $V8_DIRECTORY "third_party/icu"
$ICU_REPOSITORY = "https://chromium.googlesource.com/chromium/deps/icu.git"

$GTEST_DIRECTORY  = Join-Path $V8_DIRECTORY "testing/gtest"
$GTEST_REPOSITORY = "https://chromium.googlesource.com/external/googletest.git"

$GMOCK_DIRECTORY  = Join-Path $V8_DIRECTORY "testing/gmock"
$GMOCK_REPOSITORY = "https://chromium.googlesource.com/external/googlemock.git"

$CYGWIN_DIRECTORY  = Join-Path $V8_DIRECTORY "third_party/cygwin"
$CYGWIN_REPOSITORY = "https://chromium.googlesource.com/chromium/deps/cygwin.git"

function Download-File {
    param (
        [string]$url,
        [string]$target
    )

    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile($url, $target)
}


function Clone-Repository {
    param (
        [string]$url,
        [string]$target
    )

    if(!(Test-Path $target))
    {
        Write-Host "Cloning $url into $target"
        git clone $url $target
    }
}

function Compile-v8 {
    param (
        [string]$platform,
        [string]$configuration
    )

    Write-Host "Building v8 ($configuration)"
    msbuild /p:Configuration=$configuration /p:Platform=$platform (Join-Path $V8_DIRECTORY "tools/gyp/v8.sln")
}

function Output-v8 {
    param (
        [string]$platform,
        [string]$configuration
    )

    pushd $V8_DIRECTORY

    $t = Join-Path $OUTPUT_DIRECTORY "$platform/$configuration"

    xcopy /y build\$configuration\*.dll     "$t\bin\*"
    xcopy /y build\$configuration\lib\*.lib "$t\lib\*"
    xcopy /y include\*                      "$t\include\*"

    popd
}

# Download Nuget
if (!(Test-Path $NUGET_TOOL)) {
    Write-Host "Downloading $NUGET_FILE"
    Download-File $NUGET_DOWNLOAD_URL $NUGET_TOOL
}

Clone-Repository $V8_REPOSITORY     $V8_DIRECTORY
Clone-Repository $GYP_REPOSITORY    $GYP_DIRECTORY
Clone-Repository $ICU_REPOSITORY    $ICU_DIRECTORY
Clone-Repository $GTEST_REPOSITORY  $GTEST_DIRECTORY
Clone-Repository $GMOCK_REPOSITORY  $GMOCK_DIRECTORY
Clone-Repository $CYGWIN_REPOSITORY $CYGWIN_DIRECTORY

# Run gyp file
Write-Host "Running gyp"
python (Join-Path $V8_DIRECTORY "build/gyp_v8") -Dtarget_arch=ia32 -Dcomponent=shared_library

# Build
Compile-v8 "win32" "debug"
Output-v8  "win32" "debug"

Compile-v8 "win32" "release"
Output-v8  "win32" "release"

# Package with NuGet

copy hadouken.v8.nuspec $OUTPUT_DIRECTORY

pushd $OUTPUT_DIRECTORY
Start-Process "$NUGET_TOOL" -ArgumentList "pack hadouken.v8.nuspec -Properties version=$VERSION" -Wait -NoNewWindow
popd
