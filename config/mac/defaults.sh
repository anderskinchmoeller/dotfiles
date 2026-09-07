#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'Skipping macOS defaults: this host is not running macOS.\n'
  exit 0
fi

readonly SCREENSHOTS_FOLDER="${DOTFILES_SCREENSHOTS_FOLDER:-${HOME}/Screenshots}"

printf 'Applying macOS user preferences...\n'
osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true
mkdir -p "${SCREENSHOTS_FOLDER}"

###############################################################################
# General UI and documents
###############################################################################

defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

###############################################################################
# Keyboard and text input
###############################################################################

defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Trackpad and screen
###############################################################################

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults write com.apple.screencapture location -string "${SCREENSHOTS_FOLDER}"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Finder
###############################################################################

defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
chflags nohidden "${HOME}/Library" 2>/dev/null || true

###############################################################################
# Dock, Mission Control, and menu bar
###############################################################################

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock no-bouncing -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write NSGlobalDomain NSStatusItemSelectionPadding -int 12
defaults write NSGlobalDomain NSStatusItemSpacing -int 12

###############################################################################
# Applications
###############################################################################

defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
defaults write com.apple.appstore InAppReviewEnabled -int 0
defaults write com.apple.iCal "Show Week Numbers" -bool true
defaults write com.apple.iCal "first day of week" -int 1
defaults write com.apple.terminal StringEncodings -array 4
defaults write com.apple.Terminal ShowLineMarks -int 0
defaults write org.p0deje.Maccy historySize -int 20
defaults write org.p0deje.Maccy pasteByDefault -bool false

###############################################################################
# Optional machine identity
###############################################################################

# Host naming is the only privileged operation. It runs only when explicitly
# requested, for example:
# DOTFILES_COMPUTER_NAME="Anders-MacBook" ./install profiles/macos.conf.yaml
if [[ -n "${DOTFILES_COMPUTER_NAME:-}" ]]; then
  printf 'Setting computer name to %s...\n' "${DOTFILES_COMPUTER_NAME}"
  sudo scutil --set ComputerName "${DOTFILES_COMPUTER_NAME}"
  sudo scutil --set HostName "${DOTFILES_COMPUTER_NAME}"
  sudo scutil --set LocalHostName "${DOTFILES_COMPUTER_NAME}"
fi

if [[ "${DOTFILES_RESTART_APPS:-1}" == "1" ]]; then
  for app in Dock Finder SystemUIServer; do
    killall "${app}" >/dev/null 2>&1 || true
  done
fi

printf 'macOS preferences applied. Some changes take effect after logout.\n'
