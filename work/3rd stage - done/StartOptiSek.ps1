######################################################
#
# OptiSek Login Script 
#
# Login Script for remote login to OptiSek Secure Zone
# using SmartCard authentication via Microsoft CAPI
#
# Usage:
# powershell.exe StartOptiSek.ps1 Jumphost WindowManager
# With Jumphost: 'ProdNE', 'ProdWW' or 'Test' and
# Windowmanager: 'Xman' or 'Xmin
#
# Version: 1.0
# Date:    06.07.2015
# Autor:   Jonas Winkler (jonas.winkler@rwe.com)
# 
#######################################################

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

#######################################################
# Definition
#######################################################

# Read Script Arguments

$jumphost = $args[0]
$windowmanager = $args[1]

$xmingResolution = ""
if ($args.count -ge 3) {

    $xmingResolution = $args[2]
}

# Debug
#$jumphost = 'Test'
#$windowmanager = 'Xmin'

# Read System Architecture

# Alternertive way: (gwmi win32_processor | select -first 1).addresswidth
if ([System.IntPtr]::Size -eq 4) { # 31-bit
    $ProgramFilesRootDir = 'C:\Program Files\'
} else { # 64-bit
    $ProgramFilesRootDir = 'C:\Program Files (x86)\'
}

# Global Variabls
$UseSmartCard = $TRUE
$putty = $ProgramFilesRootDir + 'Quest Software\PuTTY\putty.exe'
$pageant = $ProgramFilesRootDir + 'Quest Software\PuTTY\pageant.exe'
$Xmanager = $ProgramFilesRootDir + 'NetSarang\Xmanager 3\Xmanager.exe'
$Xming = $ProgramFilesRootDir + 'Xming\Xming.exe'
$XmingArgs1 = ':1'
$XmingArgs2 = '-multiwindow'
$XmingArgs3 = '-screen'
$XmingArgs4 = '0'
$XmingArgs5 = $xmingResolution
$SoftkeyDirectory = 'C:\LocalData\OptiSekSoftkeys\'

# Form Objects
[System.Windows.Forms.Application]::EnableVisualStyles()
$script:formLoading = New-Object 'System.Windows.Forms.Form'
$labelLoading = New-Object 'System.Windows.Forms.Label'
$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'

#######################################################
# FUNCTION: Run Main Startup Script
#######################################################
# This runs the main startup script
function RunStartupScript
{
    #######################################################
    # Parameter Check
    #######################################################
    
    # Update Splash Screen Text
    $labelLoading.Text += "Done`r`n`Checking Parameters ... "
    $labelLoading.Refresh()
    
    # Check Jumphost Parameters
    if ($jumphost -eq 'ProdWW') {
        $JumphostServer = 'S030L0201'
    } elseif ($jumphost -eq 'ProdNE') {
        $JumphostServer = 'S030L0203'
    } 
      elseif ($jumphost -eq 'Test') {
       $JumphostServer = 'S030L0202'
    } 
      else {
        [System.Windows.Forms.MessageBox]::Show("Unbekannter Jumphost konfiguriert.","Konfigurationsfehler",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Check Window Manager Parameter
    if (($windowmanager -ne 'Xman') -and ($windowmanager -ne 'Xmin')) {
        [System.Windows.Forms.MessageBox]::Show("Unbekannter Window Manager konfiguriert.","Konfigurationsfehler",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }


    #######################################################
    # Startup Functionality
    #######################################################

    # Update Splash Screen Text
    $labelLoading.Text += "Done`r`n`Reading SmartCard ... "
    $labelLoading.Refresh()
    
    # Read SmartCard info
    $SmartCardInfo = certutil.exe -scinfo -silent

    # Try to get the user account 
    $SubjectString = $SmartCardInfo | Select-String -Pattern "Subject.*\(.*\)" | Get-Unique
    # If there is no SubjectString there might be no Smart Card present.
    if (!$SubjectString) {
        $MessageReturn = [System.Windows.Forms.MessageBox]::Show("Keine Smart Card vorhanden. Soft Key laden?","Smart Card",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
        if ($MessageReturn -eq "YES") {
            $UseSmartCard = $FALSE
        }
        else {
            # no SmartCard found, no Softkey to be loaded. Exit!
            return
        }
    }

    # We have to decide, if we will use the smardcard or a softkey
    if($UseSmartCard) {

        # Update Splash Screen Text
        $labelLoading.Text += "Done`r`n`Constructing User Information ... "
        $labelLoading.Refresh()
    
        # Split Subject string from smartcard to extract user account
        $UserID = (($SubjectString -split '\(')[1] -split '\)')[0].ToLower()

        # To load correct CAPI certificate we try to find the correct hashkey
        # Find all Lines containing "Template: RWE Admin" and their surounding ones
        $SearchResult = $SmartCardInfo | Select-String -Context 1 -Pattern "Template..RWE" | Get-Unique 
        # the result shoult look like: 
        #    SubjectAltName: Anderer Name:Prinzipalname=R073563@rwe.com
        #>   Template: RWE Admin 01
        #    47 05 55 23 5c 1d 94 41 6b 39 9b 8c 8c 7e 84 cc cb e9 6f dc

        # now get the first line of the post context and trim it
        $SmartCardHashKey = ($SearchResult.context | select -ExpandProperty PostContext | select -first 1) -replace '\s',''

        # print userID and Smart Card Hash to terminal. Comment this if no longer needed.
        $UserID
        $SmartCardHashKey
        
        # build the argument string for pageant
        $PagentArg = 'CAPI:' + $SmartCardHashKey
        
    }
    else { # we will use softkey
        
        # Update Splash Screen Text
        $labelLoading.Text += "Done`r`n`Reading SoftKey ... "
        $labelLoading.Refresh()
        
        # Read System user and trim first character
        $SystemUser = ([Environment]::UserName).SubString(1)
        $FileFilter = "*" + $SystemUser + ".ppk"
        
        # Read full path of softkey
        $SoftkeySearchResult = Get-ChildItem -Path $SoftkeyDirectory -Filter $FileFilter | Select-Object -First 1
        
        if(!$SoftkeySearchResult) { # if there is no matching SoftKey exit.
            
            [System.Windows.Forms.MessageBox]::Show("Kein Softkey für den User " + $SystmUser + " gefunden.","SoftKey",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        $PagentArg = $SoftkeySearchResult.FullName
        
        # Read UserID from Softkey
        $UserID = $SoftkeySearchResult.Name.Substring(0,7).ToLower()

    }  
    
    # Update Splash Screen Text
    $labelLoading.Text += "Done`r`n`Setting up Registry ... "
    $labelLoading.Refresh()
    

    # Set the reg entry to use agent forwarding with putty
    set-itemproperty -Path hkcu:Software\SimonTatham\PuTTY\Sessions\Default%20Settings -Name "AgentFwd" -value 1
    # Set the reg entry to use correct X11 Monitor ':1.0'
    set-itemproperty -Path hkcu:Software\SimonTatham\PuTTY\Sessions\Default%20Settings -Name "X11Display" -value ':1.0'
    set-itemproperty -Path hkcu:Software\SimonTatham\PuTTY\Sessions\Default%20Settings -Name "X11Forward" -value 1

    # Update Splash Screen Text
    $labelLoading.Text += "Done`r`n`Starting Pagent ... "
    $labelLoading.Refresh()
    $formLoading.Refresh()
    
    # now load pageant with correct certificate hash
    $arg1 = $PagentArg # when using smartcard this is the CAPI url. Else it is the softkey file of the current user.
    
    # check, if installed correctly
    if(-Not (Test-Path($pageant))) {
        [System.Windows.Forms.MessageBox]::Show("Pageant-CAC ist nicht korrekt installiert.","Pageant",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
            return
    }
    & $pageant $arg1 # TODO: before starting pageant check if it is running and kill the process if it is.

    Start-Sleep -s 1 # TODO: this is bad. try to check if pageant is running or wait for that.

    if ($windowmanager -eq 'Xmin') {
        # Update Splash Screen Text
        $labelLoading.Text += "Done`r`n`Starting Xming ... "
        $labelLoading.Refresh()
        
        # check, if installed correctly
        if(-Not (Test-Path($Xming))) {
            [System.Windows.Forms.MessageBox]::Show("Xming ist nicht korrekt installiert.","Pageant",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
                return
        }
        
        # check, if there is a resolution parameter to start xming with
        if ($xmingResolution -eq "") {
            & $Xming $XmingArgs1 $XmingArgs2 
        } else {
            & $Xming $XmingArgs1 $XmingArgs2 $XmingArgs3 $XmingArgs4 $XmingArgs5
        }
    } elseif ($windowmanager -eq 'Xman') {
        # Update Splash Screen Text
        $labelLoading.Text += "Done`r`n`Starting Xmanager ... "
        $labelLoading.Refresh()
        
        # check, if installed correctly
        if(-Not (Test-Path($Xmanager))) {
            [System.Windows.Forms.MessageBox]::Show("XManager ist nicht korrekt installiert.","Pageant",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
                return
        }
        & $Xmanager
    }

    # Update Splash Screen Text
    $labelLoading.Text += "Done`r`n`Starting Putty ... "
    $labelLoading.Refresh()
    $formLoading.Refresh()
    
    # load putty using pageant, the userid and host
    $arg1 = '-l'
    $arg2 = $JumphostServer # Select Jumphost from script arguments

    # check, if installed correctly
    if(-Not (Test-Path($putty))) {
        [System.Windows.Forms.MessageBox]::Show("Putty-CAC ist nicht korrekt installiert.","Pageant",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
            return
    }
    & $putty $arg1 $UserID $arg2
    
    # Update Splash Screen Text
    $labelLoading.Text += "Done"
    $labelLoading.Refresh()
    $formLoading.Refresh()
    
    Start-Sleep -s 5
}


#######################################################
# FUNCTION: Splash Screen
#######################################################
function CreateLoadingWindow
{

  
  # Form Events
  $Form_StateCorrection_Load =
  {
    #Correct the initial state of the form to prevent the .Net maximized form 
    #issue
    $formLoading.WindowState = $InitialFormWindowState
  }
  
  $Form_Cleanup_FormClosed =
  {
    #Remove all event handlers from the controls
    try
    {
      $formLoading.remove_Load($formLoading_Load)
      $formLoading.remove_Load($Form_StateCorrection_Load)
      $formLoading.remove_FormClosed($Form_Cleanup_FormClosed)
    }
    catch [Exception]
    { }
  }
  
  # Form Code
  #
  # formLoading
  #
  $formLoading.Controls.Add($labelLoading)
  $formLoading.BackColor = 'Window'
  $formLoading.ClientSize = '294, 140'
  $formLoading.ControlBox = $False
  $formLoading.Cursor = "AppStarting"
  $formLoading.FormBorderStyle = 'FixedToolWindow'
  $formLoading.Name = "NAME OF FORM"
  $formLoading.ShowIcon = $False
  $formLoading.ShowInTaskbar = $False
  $formLoading.StartPosition = 'CenterScreen'
  $formLoading.Text = "Starting OptiSek"
  #
  # labelLoading
  #
  $labelLoading.Location = '2, 3'
  $labelLoading.Name = " labelLoading "
  $labelLoading.Size = '250, 135'
  $labelLoading.TabIndex = 0
  $labelLoading.Text = "Initializing Startup ... "
  $formLoading.ResumeLayout()
  
  #Save the initial state of the form
  $InitialFormWindowState = $formLoading.WindowState
  #Init the OnLoad event to correct the initial state of the form
  $formLoading.add_Load($Form_StateCorrection_Load)
  #Clean up the control events
  $formLoading.add_FormClosed($Form_Cleanup_FormClosed)
  #Show the Form
  $formLoading.Show() | Out-Null
  
}

#######################################################
# Main Programm
#######################################################

CreateLoadingWindow

RunStartupScript

$formLoading.Close()

exit



