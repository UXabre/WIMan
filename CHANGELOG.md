# Changelog

## [0.0.4] - 2021-07-01
### Added
 - Automatically fetch the latest OpenSSH server package and add it to tools
   This can later be used in a script to install and configure OpenSSH capabilities on any windows target 

## [0.0.3] - 2020-03-02
### Fixed
 - Added "Elevated Console" detection (as the program is best ran as admin)
 - Configured TLS support for webclients
 - Incorrectly detected "choco"
 - Added logging output

## [0.0.2] - 2020-02-04
### Added
 - Supports detecting already installed WAIK and wopies the WinPE images from there. (otherwise fallback to installing WAIK via choco)

### BugFixes
 - Fixed issue for which installed WinPE images where not detected
 - Changed error supression pattern

## [0.0.1] - 2020-02-04
Initial Release