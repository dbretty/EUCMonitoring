# AppVeyor Testing
$projectRoot = $env:APPVEYOR_BUILD_FOLDER

Describe "JSON Template validation" {

    $scripts = Get-ChildItem "$projectRoot\Package" -Recurse -Include *.template

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object {@{file = $_}}

    It "JSON Template <file> should be valid" -TestCases $testCase {
        param($file)
        #Attempts to import JSON template file
        Get-Content -Raw -Path $file.fullname| ConvertFrom-Json -ErrorAction stop
    }

}