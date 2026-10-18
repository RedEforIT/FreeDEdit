on run argv
    set inputFolder to item 1 of argv
    set outputFolder to item 2 of argv
    set fileNames to {"sample.rtf", "sample.html", "utf8.txt", "utf16le.txt", "macroman.txt", "empty.txt", "huge.txt"}
    set resultLines to {}

    tell application id "com.apple.TextEdit"
        repeat with fileName in fileNames
            set sourcePath to inputFolder & "/" & (contents of fileName)
            set outputPath to outputFolder & "/" & (contents of fileName)
            try
                set currentDocument to open (POSIX file sourcePath)
                save currentDocument in (POSIX file outputPath)
                if (contents of fileName) ends with ".rtfd" then
                    do shell script "test -d " & quoted form of outputPath
                else
                    do shell script "test -f " & quoted form of outputPath
                end if
                set end of resultLines to ((contents of fileName) & ": opened and saved")
            on error errorMessage number errorNumber
                set end of resultLines to ((contents of fileName) & ": open/save failed (" & errorNumber & "): " & errorMessage)
            end try
        end repeat
    end tell
    set end of resultLines to "malformed.rtf: skipped; opening rejection recorded in EXPECTED.md"

    set AppleScript's text item delimiters to linefeed
    return resultLines as text
end run
