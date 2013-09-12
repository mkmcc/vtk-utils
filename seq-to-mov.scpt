#!/usr/bin/osascript
--
-- seq-to-mov.scpt: converts an image sequence to a quicktime movie.
--
-- Copyright (c) 2013 Mike McCourt (mkmcc@berkeley.edu)
--
-- Usage: seq-to-mov.scpt [first image in sequence]
--
-- Notes: 1. image sequence should be named like 1.png, 2.png, 3.png,
--           etc. or 0000.png, 0001.png, 0002.png, etc.
--        2. requires mac osx with quicktime 7 pro.
--
-- TODO:  1. handle the case where the movie file already exists
--

on run argv
  if (count of argv) > 0 then
    set filename to POSIX file (first item of argv) as alias
    set outfile  to filename as string & ".mov"
  else
    return "Usage: seq-to-mov.scpt [first image in sequence]"
  end if

  tell application "QuickTime Player 7"
    activate
    open image sequence filename frames per second 24
    export movie 1 to outfile as QuickTime movie using most recent settings

    close window 1 saving no
    -- quit
  end tell

  return "saved output in " & (first item of argv) & ".mov"
end run

-- Local Variables:
-- mode: applescript
-- End:
