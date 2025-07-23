' SecureCRT VBScript - FPGA and ROM Programming Automation
' Author: fuyunyou
' Date: 2025-07-11
' Function: Automates board programming and testing, including FPGA files, service FPGA and ROM programming

Option Explicit

' Global variables
Dim logFilePath
logFilePath = "C:/Users/PC/Documents/Work_ZhaoChen/test_scripts/02_bb_mcu_fpga/vbs_logs/BoardProgramming_" & Replace(FormatDateTime(Now, 2), "/", "-") & "_" & Replace(FormatDateTime(Now, 4), ":", "") & ".log"
' C:/Users/PC/Documents/Work_ZhaoChen/test_scripts/02_bb_mcu_fpga/ repalce with D:/SC/X9-R02底板PCBA测试工装/02_bb_mcu_fpga/

' Main function
Sub Main
    ' Set timeout to 10 seconds, can be adjusted if response is slow
    ' crt.Session.Timeout = 10000 ' Changed to proper assignment syntax

    ' Print start message
    crt.Screen.Synchronous = True
    LogToFile "============================================="
    LogToFile "| Starting Board Programming Automation      |"
    LogToFile "| Current Time: " & Now & " |"
    LogToFile "=============================================" & vbCrLf


    ' Step 1: Program Main FPGA
    SendCommandAndWait "fileload fpga 0", "Waiting for the file to be sent", "CCC"
    ' Modified file path
    SendYmodemFile "C:/Users/PC/Documents/Work_ZhaoChen/test_scripts/02_bb_mcu_fpga/2_BBFPGA_PDM-BB-LZF-beta106_Frame1328_PHY1+2ns_noDataDelay.PGA", "addr=0x0 check ok!"

    ' Reboot device
    SendCommandAndWait "hardreset", "HardReset SYSTEM NOW!!!", "Stop Timer Int for Feeding Dog!"

    ' Step 2: Program Service FPGA
    SendCommandAndWait "fileload srvfpga 0", "Waiting for the file to be sent", "CCC"
    ' Modified file path
    SendYmodemFile "C:/Users/PC/Documents/Work_ZhaoChen/test_scripts/02_bb_mcu_fpga/3_SCFPGA_PDM-SC-lzf-62-Frame94-LocalDAC-NoAD5112-X06+stp.PGA", "addr=0x800000 check ok!"

    ' Reboot device
    SendCommandAndWait "hardreset", "HardReset SYSTEM NOW!!!", "Stop Timer Int for Feeding Dog!"

    ' Step 3: Set Physical Board ID
    SendCommandAndWait "phybdidset 1", "", "write ok!phybdid=1"

    ' Reboot device
    SendCommandAndWait "hardreset", "HardReset SYSTEM NOW!!!", "Stop Timer Int for Feeding Dog!"

    ' Step 4: Set Pause Type
    SendCommandAndWait "pause 1", "", "pause type=1 OK!"

    ' Reboot device
    SendCommandAndWait "reset", "RESET SYSTEM NOW!!!", "Stop Timer Int for Feeding Dog!"

    ' Step 5: Program ROM
    SendCommandAndWait "fileload rom", "Waiting for the file to be sent", "CCC"
    ' Modified file path
    SendYmodemFile "C:/Users/PC/Documents/Work_ZhaoChen/test_scripts/02_bb_mcu_fpga/4_MCUDX_PDMBB_ROM_V9_2.00T03_X3_R01_R04.DX", "addr=0x3f00000 check ok!"

    ' Update ROM
    SendCommandAndWait "romupdate", "", "ROM_Update OK!"

    ' Final reboot
    SendCommandAndWait "hardreset", "HardReset SYSTEM NOW!!!", "Stop Timer Int for Feeding Dog!"

    ' Print completion message
    LogToFile vbCrLf & "============================================="
    LogToFile "| Board Programming Automation Complete!       |"
    LogToFile "| Completion Time: " & Now & " |"
    LogToFile "=============================================" & vbCrLf

    crt.Dialog.MessageBox "Burn completed!"

End Sub

' Write to log file (with timestamp)
Sub LogToFile(message)
    Dim fso, file
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set file = fso.OpenTextFile(logFilePath, 8, True) ' 8=Append mode
    file.WriteLine FormatDateTime(Now, 0) & " - " & message
    file.Close
End Sub

' Send command and wait for specific response
Sub SendCommandAndWait(command, expectedPrompt, successResponse)
    crt.Screen.Send command & vbCr

    ' Log command
    LogToFile "[AUTO] Command sent: " & command

    ' Wait for command prompt
    If expectedPrompt <> "" Then
        If Not crt.Screen.WaitForString(expectedPrompt, 10) Then
            LogToFile "[ERROR] Expected prompt not received: " & expectedPrompt

            crt.Dialog.MessageBox "Error: Expected prompt not received: " & expectedPrompt & vbCrLf
            Exit Sub
        End If
    End If

    ' Wait for success response
    If successResponse <> "" Then
        If Not crt.Screen.WaitForString(successResponse, 60) Then
            LogToFile "[ERROR] Command execution timeout or failed: " & command
            crt.Dialog.MessageBox "Error: Command execution timeout or failed: " & command & vbCrLf
            Exit Sub
        End If
        LogToFile "[SUCCESS] Command executed successfully: " & command
    End If
End Sub


' Send file via Ymodem
Sub SendYmodemFile(filename, successResponse)
    ' Log file transfer
    LogToFile "[AUTO] Preparing to send file: " & filename

    crt.FileTransfer.AddToUploadList filename
    LogToFile "Add file to upload list "

    ' Start Ymodem transfer
    crt.FileTransfer.sendYmodem

    ' Wait for success response
    If successResponse <> "" Then
        If Not crt.Screen.WaitForString(successResponse, 180) Then
            LogToFile "[ERROR] File verification failed: " & filename
            crt.Dialog.MessageBox "Error: File verification failed: " & filename & vbCrLf
            Exit Sub
        End If
    End If

    LogToFile "[SUCCESS] File transferred successfully: " & filename
End Sub
