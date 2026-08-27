to get repo is ids open powershell and write this command 

$r = Invoke-RestMethod `
>>   -Uri "https://api.github.com/repos/liraz-pat/nizanim-final-project" `
>>   -Headers @{ "User-Agent" = "PowerShell" }

now you can continue to the aws-github-ecr-oidc-permissions.md