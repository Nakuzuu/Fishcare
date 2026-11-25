param([string]$Action='inspect',[int]$X=0,[int]$Y=0,[string]$Value='')
$adb='C:\Users\basti\AppData\Local\Android\sdk\platform-tools\adb.exe'
switch($Action){
 'tap' { & $adb shell input tap $X $Y }
 'text' { & $adb shell input text $Value }
 'back' { & $adb shell input keyevent 4 }
 'swipe' { & $adb shell input swipe 650 2200 650 1000 500 }
}
Start-Sleep -Milliseconds 800
& $adb shell uiautomator dump /sdcard/fishcare-ui.xml | Out-Null
[xml]$ui=(& $adb shell cat /sdcard/fishcare-ui.xml)
$ui.SelectNodes('//node[@content-desc!="" or @text!="" or @class="android.widget.EditText"]') | ForEach-Object { $_.'content-desc' + ' ' + $_.text + ' ' + $_.bounds }
