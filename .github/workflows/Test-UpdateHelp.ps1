$ERRORACTIONPREFERENCE = $WARNINGPREFERENCE = [System.Management.Automation.ActionPreference]:: STOP
INSTALL-MODULE PESTER
IPMO PESTER
UPDATE-HELP -M:Microsoft.PowerShell.Core -UI:EN-US -SO:NUL -EA:ST | SHOULD -THROW -E:UnableToRetrieveHelpInfoXml,Microsoft.PowerShell.Commands.UpdateHelpCommand
