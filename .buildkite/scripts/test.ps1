$ErrorActionPreference = "Stop" # set -e
# Forcing to checkout again all the files with a correct autocrlf.
# Doing this here because we cannot set git clone options before.
function fixCRLF {
    Write-Host "-- Fixing CRLF in git checkout --"
    git config core.autocrlf input
    git rm --quiet --cached -r .
    git reset --quiet --hard
}

function withGolang($version) {
    Write-Host "-- Install golang --"
    choco install -y golang --version $version
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    refreshenv
    go version
    go env
}

function withGoJUnitReport {
    Write-Host "-- Install go-junit-report --"
    go install github.com/jstemmer/go-junit-report/v2
}

function goInstallMethod {

}

# Prepare enviroment
fixCRLF
withGolang $env:SETUP_GOLANG_VERSION
withGoJUnitReport

# Run test
$ErrorActionPreference = "Continue" # set +e
mkdir -p build
$OUT_FILE="build\output-report.out"
go test "./..." -v > $OUT_FILE | type $OUT_FILE
$EXITCODE=$LASTEXITCODE
$ErrorActionPreference = "Stop"

Get-Content $OUT_FILE | go-junit-report > "build\uni-junit-$GO_VERSION.xml"
Get-Content "build\uni-junit-$GO_VERSION.xml" -Encoding Unicode | Set-Content -Encoding UTF8 "build\junit-$GO_VERSION.xml"
Remove-Item "build\uni-junit-$GO_VERSION.xml", "$OUT_FILE"
