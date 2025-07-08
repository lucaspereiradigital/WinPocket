<# :
    @setLocal enableExtensions disableDelayedExpansion
    @echo off

    set "scriptPath=%~f0"
    set "getScriptContent=[System.IO.File]::ReadAllText('%scriptPath:'=''%')"

    set ^"args=%*"
    set "fixedArgs="

    if defined args (
        for %%i in (%args:'=''%) do (
            call :fixArgs %%i
        )
    )

    powershell -Sta -NoProfile -Command "& ([scriptblock]::Create(%getScriptContent%))%fixedArgs%"
    exit /b

    :fixArgs
        set ^"arg=%1"

        if "%arg:~0,1%%arg:~-1%" == """" (
            set "fixedArgs=%fixedArgs% '%arg:~1,-1%'"
        ) else (
            set "fixedArgs=%fixedArgs% %arg%"
        )

        exit /b
#>

try
{
    $winId = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $winPrinc = New-Object -Typename System.Security.Principal.WindowsPrincipal -ArgumentList $winId
    $isAdmin = $winPrinc.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
finally
{
    if ($null -ne $winId)
    {
        $winId.Dispose()
    }
}

if (-not $isAdmin)
{
    if ($env:fixedArgs -match ' -Restarted$')
    {
        exit 1
    }

    $argList = "/c `"`"$env:scriptPath`""

    if ($null -ne $env:args)
    {
        $argList = "$argList $env:args"
    }

    $argList = "$argList -Restarted`""

    Start-Process -FilePath cmd -ArgumentList $argList -Verb RunAs
    
    if (-not $?)
    {
        exit 1
    }

    exit
}

$productName = 'WinPocket'
$Host.UI.RawUI.WindowTitle = $productName
$nl = [System.Environment]::NewLine

$psVersion = $PSVersionTable.PSVersion.Major

if ($psVersion -lt 4)
{
    Write-Host -Object "Error$nl" -ForegroundColor Red
    Write-Host -Object "$productName requires Windows PowerShell 4 or higher.$nl"
    Start-Sleep -Seconds 10
    exit 1
}

$winBuildNumber = [int](Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber

if ($winBuildNumber -lt 9600)
{
    Write-Host -Object "Error$nl" -ForegroundColor Red
    Write-Host -Object "$productName requires Windows 8.1 or higher.$nl"
    Start-Sleep -Seconds 10
    exit 1
}

Add-Type -AssemblyName PresentationFramework

$mainWindowXaml =
@'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    Background="#FFF3F3F3"
    ResizeMode="CanMinimize"
    SizeToContent="WidthAndHeight"
    SnapsToDevicePixels="True"
    Title="WinPocket"
    WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#FFF3F3F3"/>
            <Setter Property="Padding" Value="6,3"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="HorizontalAlignment" Value="Left"/>
            <Setter Property="Margin" Value="8,8,8,0"/>
            <Setter Property="Padding" Value="0"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
    </Window.Resources>
    <ScrollViewer HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
        <Grid Name="Container">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="8"/>
                <ColumnDefinition/>
                <ColumnDefinition Width="8"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height="8"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition MinHeight="48"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="8"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Label
                Content="Disk"
                Grid.Column="1"
                Grid.Row="1"/>
            <ComboBox
                Grid.Column="1"
                Grid.Row="2"
                Margin="8,0,8,8"
                Name="DiskCbBox"
                ToolTip="Allows to choose a disk from the system"/>
            <Label
                Content="Partition style"
                Grid.Column="1"
                Grid.Row="3"/>
            <Grid Grid.Column="1" Grid.Row="4">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition MinWidth="16"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <RadioButton
                    Content="MBR"
                    IsChecked="True"
                    Margin="8,0,8,8"
                    Name="MbrRdBtn"
                    ToolTip="MBR, a partition style"/>
                <RadioButton
                    Content="GPT"
                    Grid.Column="1"
                    Margin="8,0,8,8"
                    Name="GptRdBtn"
                    ToolTip="GPT, a partition style"/>
                <Button
                    Background="#FF333333"
                    Content="Refresh disk list"
                    Grid.Column="3"
                    Margin="8,0,8,8"
                    Name="RefreshDiskListBtn"
                    ToolTip="Refreshes the disk list"/>
                <Button
                    Background="#FF333333"
                    Content="Select image file"
                    Grid.Column="4"
                    Margin="8,0,8,8"
                    Name="SelectImageFileBtn"
                    ToolTip="Opens image file selector"/>
                <Button
                    Background="#FF333333"
                    Content="Refresh windows image list"
                    Grid.Column="5"
                    Margin="8,0,8,8"
                    Name="RefreshWinImageListBtn"
                    ToolTip="Refreshes the windows image list"/>
            </Grid>
            <Label
                Content="Image file (*.wim; *.esd)"
                Grid.Column="1"
                Grid.Row="5"/>
            <TextBox
                AllowDrop="False"
                Grid.Column="1"
                Grid.Row="6"
                HorizontalScrollBarVisibility="Auto"
                IsReadOnly="True"
                IsUndoEnabled="False"
                Margin="8,0,8,8"
                Name="ImageFileTxtBox"
                Padding="0,3"
                ToolTip="Shows the path of the selected image file"/>
            <Label
                Content="Windows image"
                Grid.Column="1"
                Grid.Row="7"/>
            <ComboBox
                Grid.Column="1"
                Grid.Row="8"
                Margin="8,0,8,8"
                Name="WinImageCbBox"
                ToolTip="Allows to choose an Windows image from the selected image file"/>
            <Grid Grid.Column="1" Grid.Row="10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button
                    Background="Blue"
                    Content="Help"
                    Margin="8"
                    Name="HelpBtn"
                    ToolTip="Opens a help message box"/>
                <Button
                    Background="Green"
                    Content="Create"
                    Grid.Column="2"
                    IsDefault="True"
                    Margin="8"
                    Name="CreateBtn"
                    ToolTip="Starts the creation of Windows To Go"/>
            </Grid>
            <ProgressBar
                BorderThickness="0"
                Grid.ColumnSpan="3"
                Grid.Row="13"
                Name="ProgBar"/>
            <TextBlock
                FontWeight="Bold"
                Grid.Column="1"
                Grid.Row="13"
                Margin="8,4"
                Name="StatusText"
                Text="Ready"
                TextAlignment="Center"
                ToolTip="Shows the status of the creation of Windows To Go"
                VerticalAlignment="Center"/>
        </Grid>
    </ScrollViewer>
</Window>
'@

$sanPolicyXml =
@'
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="offlineServicing">
        <component
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            language="neutral"
            name="Microsoft-Windows-PartitionManager"
            processorArchitecture="x86"
            publicKeyToken="31bf3856ad364e35"
            versionScope="nonSxS">
            <SanPolicy>4</SanPolicy>
        </component>
        <component
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            language="neutral"
            name="Microsoft-Windows-PartitionManager"
            processorArchitecture="amd64"
            publicKeyToken="31bf3856ad364e35"
            versionScope="nonSxS">
            <SanPolicy>4</SanPolicy>
        </component>
    </settings>
</unattend>
'@

$unattendXml =
@'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            language="neutral"
            name="Microsoft-Windows-WinRE-RecoveryAgent"
            processorArchitecture="x86"
            publicKeyToken="31bf3856ad364e35"
            versionScope="nonSxS">
            <UninstallWindowsRE>true</UninstallWindowsRE>
        </component>
        <component
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            language="neutral"
            name="Microsoft-Windows-WinRE-RecoveryAgent"
            processorArchitecture="amd64"
            publicKeyToken="31bf3856ad364e35"
            versionScope="nonSxS">
            <UninstallWindowsRE>true</UninstallWindowsRE>
        </component>
    </settings>
</unattend>
'@

$RefreshDiskListBtn_Click =
{
    $ui.DiskCbBox.Items.Clear()
    $backend.Disks.Clear()

    $disks = Get-Disk | Where-Object -FilterScript {
        -not [string]::IsNullOrEmpty($_.FriendlyName) -and
        -not [string]::IsNullOrEmpty($_.SerialNumber) -and
        $_.Size -gt 30e9 -and
        -not $_.IsBoot -and
        -not $_.IsSystem
    }

    if ($null -eq $disks)
    {
        return
    }

    foreach ($disk in $disks)
    {
        if ($disk.Size -lt 1e12)
        {
            $ui.DiskCbBox.Items.Add("$($disk.FriendlyName) | $([Math]::Round($disk.Size / 1e9)) GB | $($disk.SerialNumber)")
        }
        else
        {
            $ui.DiskCbBox.Items.Add("$($disk.FriendlyName) | $([Math]::Round($disk.Size / 1e12, 1)) TB | $($disk.SerialNumber)")
        }

        $backend.Disks.Add($disk)
    }

    $ui.DiskCbBox.SelectedIndex = 0
}

$SelectImageFileBtn_Click =
{
    $fileSelector = New-Object -Typename Microsoft.Win32.OpenFileDialog
    $fileSelector.Title = 'Select an image file'
    $fileSelector.Filter = 'Image files (*.wim; *.esd)|*.wim;*.esd'

    if ($fileSelector.ShowDialog() -eq $true)
    {
        $ui.ImageFileTxtBox.Text = $fileSelector.FileName
        & $RefreshWinImageListBtn_Click
    }
}

$RefreshWinImageListBtn_Click =
{
    $ui.WinImageCbBox.Items.Clear()

    if (-not (Test-Path -LiteralPath $ui.ImageFileTxtBox.Text))
    {
        $ui.ImageFileTxtBox.Text = [string]::Empty
        return
    }

    $winImages = Get-WindowsImage -ImagePath $ui.ImageFileTxtBox.Text

    foreach ($winImage in $winImages)
    {
        $ui.WinImageCbBox.Items.Add($winImage.ImageName)
    }
    
    $ui.WinImageCbBox.SelectedIndex = 0
}

$HelpBtn_Click =
{
    $helpMsg = 
@'
Hello, world!
'@

    [System.Windows.MessageBox]::Show($ui.MainWindow, $helpMsg, 'Help', 'OK')
}

$CreateBtn_Click =
{
    function Set-StatusText
    {
        param
        (
            [string]$Text,
            [string]$ErrorText
        )

        $backend.ErrorText = $ErrorText

        $ui.MainWindow.Dispatcher.Invoke(
        {
            $ui.StatusText.Text = $Text
        })

        Start-Sleep -Milliseconds 500
    }

    function Enable-UI
    {
        param
        (
            [string]$Message,
            [string]$Title,
            [string]$Button = 'OK',
            [string]$Image = 'None',
            [switch]$RefreshDiskList,
            [switch]$RefreshWinImageList
        )

        $ui.MainWindow.Dispatcher.Invoke(
        {
            $ui.ProgBar.IsIndeterminate = $false
            $ui.StatusText.Text = 'Ready'
            $ui.Container.IsEnabled = $true

            if ($Message -ne [string]::Empty)
            {
                [System.Windows.MessageBox]::Show($ui.MainWindow, $Message, $Title, $Button, $Image)
            }
            
            if ($RefreshDiskList)
            {
                & $backend.RefreshDiskListBtn_Click -NoErrorMessage
            }
            elseif ($RefreshWinImageList)
            {
                & $RefreshWinImageListBtn_Click
            }
        })
    }

    Start-Sleep -Milliseconds 500

    $chosenDisk = Get-CimInstance -InputObject $backend.Disks[$backend.DiskCbBox_SelectedIndex]

    if ($null -eq $chosenDisk)
    {
        Enable-UI -Message 'The chosen disk could not be found!' -Title Error -Button OK -Image Error -RefreshDiskList
        return
    }

    if (-not (Test-Path -LiteralPath $backend.ImageFileTxtBox_Text))
    {
        Enable-UI -Message 'The selected image file could not be found!' -Title Error -Button OK -Image Error
        return
    }

    $chosenWinImage = Get-WindowsImage -ImagePath $backend.ImageFileTxtBox_Text -Name $backend.WinImageCbBox_Text

    if ($null -eq $chosenWinImage)
    {
        Enable-UI -Message 'The chosen Windows image could not be found!' -Title Error -Button OK -Image Error -RefreshWinImageList
        return
    }

    Set-StatusText -Text 'Waiting for confirmation'
    $isChosenDiskFixed = $diskProperties.MediaType -match 'hard disk media$'

    if (-not $isChosenDiskFixed)
    {
        $mediaTypeMsg =
            'The chosen disk is flagged by Windows as "Removable Media".' + $nl +
            $nl +
            'This means that Windows To Go will probably not work if the chosen windows image contains ' +
            'an old Windows version (Windows 10 v1607 [10.0.14393] - August 2, 2016 - or lower).' + $nl +
            $nl +
            'Do you want to proceed?'

        $btnPressCode = [Win32.User32]::MessageBox($backend.MainWindowHandle, $mediaTypeMsg, 'Warning', 52)

        if ($btnPressCode -ne 6)
        {
            Enable-UI
            return
        }
    }

    $dataWipeMsg = 
        'All data and partitions of the chosen disk will be wiped!' + $nl +
        $nl +
        'Do you want to proceed?'
        
    $btnPressCode = [Win32.User32]::MessageBox($backend.MainWindowHandle, $dataWipeMsg, 'Warning', 52)

    if ($btnPressCode -ne 6)
    {
        Enable-UI
        return
    }
    
    try
    {
        if ($chosenDisk.PartitionStyle -eq 'MBR' -or $chosenDisk.PartitionStyle -eq 'GPT')
        {
            Set-StatusText -Text 'Cleaning disk' -ErrorText 'cleaning disk'
            Clear-Disk -InputObject $chosenDisk -RemoveData -RemoveOEM -Confirm:$false
        }

        if ($isChosenDiskFixed)
        {
            Set-StatusText -Text 'Initializing disk and setting partition style' -ErrorText 'initializing disk or setting partition style'
            Initialize-Disk -InputObject $chosenDisk -PartitionStyle $backend.PartitionStyleComboBox_Text -Confirm:$false

            if ($backend.PartitionStyleComboBox_Text -eq 'GPT')
            {
                $undesiredPartition = Get-Partition -Disk $chosenDisk
                Remove-Partition -InputObject $undesiredPartition -Confirm:$false
            }
        }
        else
        {
            Set-StatusText -Text 'Setting partition style' -ErrorText 'setting partition style'
            Set-Disk -InputObject $chosenDisk -PartitionStyle $backend.PartitionStyleComboBox_Text
        }

        Set-StatusText -Text 'Creating partitions' -ErrorText 'creating partitions'

        if ($backend.PartitionStyleComboBox_Text -eq 'MBR')
        {
            $systemPartition = New-Partition -InputObject $chosenDisk -Size 350MB -AssignDriveLetter -IsActive
            $osPartition = New-Partition -InputObject $chosenDisk -UseMaximumSize -AssignDriveLetter
        }
        else
        {
            $systemPartition = New-Partition -InputObject $chosenDisk -Size 100MB -AssignDriveLetter -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
            $reservedPartition = New-Partition -InputObject $chosenDisk -Size 16MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
            $osPartition = New-Partition -InputObject $chosenDisk -Size ($chosenDisk.LargestFreeExtent - $systemPartition.Size - $reservedPartition.Size - 1000MB) -AssignDriveLetter
            $recoveryPartition = New-Partition -InputObject $chosenDisk -UseMaximumSize -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}'

            # Rever isso, pois está acessando o disco pelo número, possível risco de acesso ao disco errado
            $setGptAttributes =
@"
select disk $($chosenDisk.Number)
select partition 1
gpt attributes=0x8000000000000000
select partition 2
gpt attributes=0x8000000000000000
select partition 4
gpt attributes=0x8000000000000001
exit
"@

            $setGptAttributes | diskpart
        }

        Set-StatusText -Text 'Formatting volumes' -ErrorText 'formatting volumes'
        Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false
        Format-Volume -Partition $osPartition -FileSystem NTFS -Force -Confirm:$false
        Format-Volume -Partition $recoveryPartition -FileSystem NTFS -Force -Confirm:$false

        <#
        if ($isChosenDiskFixed)
        {
            Set-StatusText -Text 'Setting NoDefaultDriveLetter flag' -ErrorText 'setting NoDefaultDriveLetter flag'
            Set-Partition -InputObject $osPartition -NoDefaultDriveLetter $true -Confirm:$false
        }
        #>
        
        Set-StatusText -Text 'Applying Windows image (this might take a while)' -ErrorText 'applying Windows image'
        Expand-WindowsImage -ImagePath $backend.ImageFileTxtBox_Text -Name $backend.WinImageCbBox_Text -ApplyPath "$($osPartition.DriveLetter):\"

        Set-StatusText -Text 'Configuring boot files' -ErrorText 'configuring boot files'

        if ($backend.PartitionStyleComboBox_Text -eq 'MBR')
        {
            Invoke-Expression -Command "$($osPartition.DriveLetter):\Windows\System32\bcdboot.exe $($osPartition.DriveLetter):\Windows /s $($systemPartition.DriveLetter):\ /f ALL"
        }
        else
        {
            Invoke-Expression -Command "$($osPartition.DriveLetter):\Windows\System32\bcdboot.exe $($osPartition.DriveLetter):\Windows /s $($systemPartition.DriveLetter):\ /f UEFI"
        }

        Set-StatusText -Text 'Hiding boot partition' -ErrorText 'hiding boot partition'
        Remove-PartitionAccessPath -InputObject $systemPartition -AccessPath "$($systemPartition.DriveLetter):\"

        Set-StatusText -Text 'Creating san__policy.xml' -ErrorText 'creating san_policy.xml'
        New-Item -Path "$($osPartition.DriveLetter):\" -Name san_policy.xml -ItemType File -Value $backend.SanPolicyXml -Force -Confirm:$false
        # New-Item -Path "$($osPartition.DriveLetter):\Windows\System32\Sysprep\" -Name unattend.xml -ItemType File -Value $backend.UnattendXml -Force -Confirm:$false

        Set-StatusText -Text 'Applying san__policy.xml' -ErrorText 'applying san_policy.xml'
        Use-WindowsUnattend -UnattendPath "$($osPartition.DriveLetter):\san_policy.xml" -Path "$($osPartition.DriveLetter):\"

        Set-StatusText -Text 'Deleting san__policy.xml' -ErrorText 'deleting san_policy.xml'
        Remove-Item -LiteralPath "$($osPartition.DriveLetter):\san_policy.xml" -Force -Confirm:$false

        Set-StatusText -Text 'Finishing'
        Enable-UI -Message "Windows To Go sucessfully created!$nl$nlOperation finished." -Title Success -Button OK -Image Information
    }
    catch
    {
        Enable-UI -Message "The following error ocurred while $($backend.ErrorText):$nl$nl$($_.Exception.Message)" -Title Error -Button OK -Image Error
    }
}

$ui = [System.Collections.Hashtable]::Synchronized((New-Object -Typename System.Collections.Hashtable -ArgumentList 12))
$ui.MainWindow = [System.Windows.Markup.XamlReader]::Parse($mainWindowXaml)
$ui.Container = $ui.MainWindow.FindName('Container')
$ui.DiskCbBox = $ui.MainWindow.FindName('DiskCbBox')
$ui.MbrRdBtn = $ui.MainWindow.FindName('MbrRdBtn')
$ui.RefreshDiskListBtn = $ui.MainWindow.FindName('RefreshDiskListBtn')
$ui.SelectImageFileBtn = $ui.MainWindow.FindName('SelectImageFileBtn')
$ui.RefreshWinImageListBtn = $ui.MainWindow.FindName('RefreshWinImageListBtn')
$ui.ImageFileTxtBox = $ui.MainWindow.FindName('ImageFileTxtBox')
$ui.WinImageCbBox = $ui.MainWindow.FindName('WinImageCbBox')
$ui.HelpBtn = $ui.MainWindow.FindName('HelpBtn')
$ui.ProgBar = $ui.MainWindow.FindName('ProgBar')
$ui.StatusText = $ui.MainWindow.FindName('StatusText')
$ui.CreateBtn = $ui.MainWindow.FindName('CreateBtn')

$backend = [System.Collections.Hashtable]::Synchronized((New-Object -Typename System.Collections.Hashtable -ArgumentList 11))
$backend.Disks = New-Object -Typename System.Collections.Generic.List[ciminstance]
$backend.RefreshDiskListBtn_Click = $RefreshDiskListBtn_Click
$backend.SanPolicyXml = $sanPolicyXml
$backend.UnattendXml = $unattendXml

$ui.RefreshDiskListBtn.Add_Click(
{
    & $RefreshDiskListBtn_Click
})

$ui.SelectImageFileBtn.Add_Click(
{
    & $SelectImageFileBtn_Click
})

$ui.RefreshWinImageListBtn.Add_Click(
{
    & $RefreshWinImageListBtn_Click
})

$ui.HelpBtn.Add_Click(
{
    & $HelpBtn_Click
})

$ui.CreateBtn.Add_Click(
{
    if ($ui.DiskCbBox.SelectedIndex -eq -1)
    {
        [System.Windows.MessageBox]::Show($ui.MainWindow, 'No disks were detected!', 'Error', 'OK', 'Error')
        & $RefreshDiskListBtn_Click
        return
    }

    if ($ui.ImageFileTxtBox.Text -eq [string]::Empty)
    {
        [System.Windows.MessageBox]::Show($ui.MainWindow, 'No image files were selected!', 'Error', 'OK', 'Error')
        return
    }

    $backend.DiskCbBox_Text = $ui.DiskCbBox.Text
    
    if ($ui.MbrRdBtn.IsChecked)
    {
        $backend.PartitionStyleComboBox_Text = 'MBR'
    }
    else
    {
        $backend.PartitionStyleComboBox_Text = 'GPT'
    }

    $backend.ImageFileTxtBox_Text = $ui.ImageFileTxtBox.Text
    $backend.DiskCbBox_SelectedIndex = $ui.DiskCbBox.SelectedIndex
    $backend.WinImageCbBox_Text = $ui.WinImageCbBox.Text

    $ui.Container.IsEnabled = $false
    $ui.StatusText.Text = 'Starting'
    $ui.ProgBar.IsIndeterminate = $true

    $powershell.BeginInvoke()
})

$ui.MainWindow.Add_ContentRendered(
{
    <#$ui.MainWindow.MinWidth = $ui.MainWindow.ActualWidth
    $ui.MainWindow.MinHeight = $ui.MainWindow.ActualHeight
    $ui.MainWindow.SizeToContent = 'Manual'#>
    $ui.DiskCbBox.MaxWidth = $ui.DiskCbBox.ActualWidth
    $ui.ImageFileTxtBox.MaxWidth = $ui.ImageFileTxtBox.ActualWidth
    $ui.WinImageCbBox.MaxWidth = $ui.WinImageCbBox.ActualWidth
    $ui.StatusText.MaxWidth = $ui.StatusText.ActualWidth
    & $RefreshDiskListBtn_Click
    $backend.MainWindowHandle = (New-Object -Typename System.Windows.Interop.WindowInteropHelper -ArgumentList $ui.MainWindow).Handle
})

$user32Functions =
@'
[DllImport("user32.dll")]
public static extern int MessageBox(IntPtr hWnd, string text, string caption, uint type);
'@

Add-Type -Name User32 -MemberDefinition $user32Functions -Namespace Win32

$iss = [initialsessionstate]::CreateDefault2()
$iss.Variables.Add((New-Object -Typename System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'ui', $ui, 'Hashtable of UI objects.'))
$iss.Variables.Add((New-Object -Typename System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'backend', $backend, 'Hashtable of backend objects.'))

try
{
    $runspace = [runspacefactory]::CreateRunspace($iss)
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    
    try
    {
        $powershell = [powershell]::Create()
        $powershell.Runspace = $runspace
        $powershell.AddScript($CreateBtn_Click) | Out-Null

        try
        {
            $guid = '43b2f84b-d5bf-48e1-8c21-3575cefa1662'
            $wasMutexCreated = $false
            $mutex = New-Object -Typename System.Threading.Mutex -ArgumentList $true, "$productName {$guid}", ([ref]$wasMutexCreated)

            if (-not $wasMutexCreated)
            {
                $mutex.Dispose()
                [System.Windows.MessageBox]::Show("$productName já está em execução!", 'Erro', 'OK', 'Error') | Out-Null
                exit 1
            }

            $ui.MainWindow.ShowDialog() | Out-Null
        }
        finally
        {
            if ($null -ne $mutex)
            {
                $mutex.Dispose()
            }
        }
    }
    finally
    {
        if ($null -ne $powershell)
        {
            $powershell.Dispose()
        }
    }
}
finally
{
    if ($null -ne $runspace)
    {
        $runspace.Dispose()
    }
}
