on run argv
    set inputFolder to item 1 of argv
    set outputFolder to item 2 of argv
    set fileNames to {"sample.docx"}
    set resultLines to {}
    tell application id "com.apple.TextEdit"
        repeat with fileName in fileNames
            set sourcePath to inputFolder & "/" & (contents of fileName)
            set outputPath to outputFolder & "/" & (contents of fileName)
            try
                set currentDocument to open (POSIX file sourcePath)
                save currentDocument in (POSIX file outputPath)
                do shell script "test -f " & quoted form of outputPath
                set end of resultLines to ((contents of fileName) & ": opened and saved")
            on error errorMessage number errorNumber
                set end of resultLines to ((contents of fileName) & ": open/save failed (" & errorNumber & "): " & errorMessage)
            end try
        end repeat
    end tell
    set AppleScript's text item delimiters to linefeed
    return resultLines as text
end run
