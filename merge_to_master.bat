@echo off
merge_to_master %1 "Leeches.esm" --overwrite --remove-deleted --apply-moved-references
pause