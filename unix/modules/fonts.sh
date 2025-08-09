#!/bin/bash

# Fonts Module
# Handles font installation across different platforms

# Source common functions
if [[ -z "${FONTS_SCRIPT_DIR:-}" ]]; then
    FONTS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "${FONTS_SCRIPT_DIR}/common.sh"

# Font directories by platform
get_font_directory() {
  local scope="${1:-user}" # user or system

  case "$(detect_platform)" in
    darwin)
      if [[ "$scope" == "system" ]]; then
        echo "/Library/Fonts"
      else
        echo "$HOME/Library/Fonts"
      fi
      ;;
    fedora|gnu)
      if [[ "$scope" == "system" ]]; then
        echo "/usr/share/fonts/local"
      else
        echo "$HOME/.local/share/fonts"
      fi
      ;;
    android)
      echo "$HOME/.fonts"
      ;;
    *)
      echo "$HOME/.fonts"
      ;;
  esac
}

# Function to validate font files
validate_font() {
  local font_file="$1"

  if [[ ! -f "$font_file" ]]; then
    log_error "Font file not found: $font_file"
    return 1
  fi

  # Check file extension
  case "${font_file##*.}" in
    ttf|TTF|otf|OTF|woff|WOFF|woff2|WOFF2)
      return 0
      ;;
    *)
      log_error "Unsupported font format: ${font_file##*.}"
      return 1
      ;;
  esac
}

# Function to install a single font
install_font() {
  local font_file="$1"
  local scope="${2:-user}"
  local font_dir

  # Validate font file
  if ! validate_font "$font_file"; then
    return 1
  fi

  font_dir=$(get_font_directory "$scope")

  # Create font directory if it doesn't exist
  if [[ "$scope" == "system" ]]; then
    sudo mkdir -p "$font_dir"
  else
    mkdir -p "$font_dir"
  fi

  log_info "Installing font: $(basename "$font_file") to $font_dir"

  # Copy font file
  if [[ "$scope" == "system" ]]; then
    sudo cp "$font_file" "$font_dir/"
  else
    cp "$font_file" "$font_dir/"
  fi

  if [[ $? -eq 0 ]]; then
    log_info "Successfully installed: $(basename "$font_file")"
    return 0
  else
    log_error "Failed to install: $(basename "$font_file")"
    return 1
  fi
}

# Function to install fonts from a directory
install_fonts_from_directory() {
  local font_directory="$1"
  local scope="${2:-user}"
  local installed_count=0
  local failed_count=0

  if [[ ! -d "$font_directory" ]]; then
    log_error "Font directory not found: $font_directory"
    return 1
  fi

  log_step "Installing fonts from $font_directory..."

  # Find all font files
  while IFS= read -r -d '' font_file; do
    if install_font "$font_file" "$scope"; then
      ((installed_count++))
    else
      ((failed_count++))
    fi
  done < <(find "$font_directory" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.woff" -o -iname "*.woff2" \) -print0)

  log_info "Font installation completed: $installed_count installed, $failed_count failed"

  if [[ $installed_count -gt 0 ]]; then
    refresh_font_cache
  fi

  return 0
}

# Function to refresh font cache
refresh_font_cache() {
  log_info "Refreshing font cache..."

  case "$(detect_platform)" in
    darwin)
      # macOS automatically handles font cache
      log_info "macOS will automatically refresh font cache"
      ;;
    fedora|gnu)
      if command_exists fc-cache; then
        fc-cache -f -v
        log_info "Font cache refreshed"
      else
        log_warn "fc-cache not found. Font cache may not be updated."
      fi
      ;;
    android)
      log_info "Android font cache refresh not required"
      ;;
    *)
      if command_exists fc-cache; then
        fc-cache -f -v
      fi
      ;;
  esac
}

# Function to list installed fonts
list_installed_fonts() {
  local scope="${1:-user}"
  local font_dir

  font_dir=$(get_font_directory "$scope")

  if [[ ! -d "$font_dir" ]]; then
    log_warn "Font directory not found: $font_dir"
    return 1
  fi

  log_info "Fonts installed in $font_dir:"
  find "$font_dir" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.woff" -o -iname "*.woff2" \) -exec basename {} \; | sort
}

# Function to install fonts from the repository
install_repo_fonts() {
  local fonts_dir="${LOCAL_PATH}/fonts"
  local scope="${1:-user}"

  if [[ ! -d "$fonts_dir" ]]; then
    log_error "Repository fonts directory not found: $fonts_dir"
    return 1
  fi

  log_step "Installing fonts from repository..."
  install_fonts_from_directory "$fonts_dir" "$scope"
}

# Function to install specific font families
install_font_family() {
  local family_name="$1"
  local scope="${2:-user}"
  local fonts_dir="${LOCAL_PATH}/fonts"

  if [[ ! -d "$fonts_dir" ]]; then
    log_error "Repository fonts directory not found: $fonts_dir"
    return 1
  fi

  log_step "Installing $family_name fonts..."

  local installed_count=0
  local failed_count=0

  # Find fonts matching the family name
  while IFS= read -r -d '' font_file; do
    if install_font "$font_file" "$scope"; then
      ((installed_count++))
    else
      ((failed_count++))
    fi
  done < <(find "$fonts_dir" -type f \( -iname "*${family_name}*" \) \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.woff" -o -iname "*.woff2" \) -print0)

  if [[ $installed_count -eq 0 ]]; then
    log_warn "No fonts found matching: $family_name"
    return 1
  fi

  log_info "$family_name font installation completed: $installed_count installed, $failed_count failed"

  if [[ $installed_count -gt 0 ]]; then
    refresh_font_cache
  fi

  return 0
}

# Function to remove fonts
remove_font() {
  local font_name="$1"
  local scope="${2:-user}"
  local font_dir

  font_dir=$(get_font_directory "$scope")

  if [[ ! -d "$font_dir" ]]; then
    log_error "Font directory not found: $font_dir"
    return 1
  fi

  local font_path="$font_dir/$font_name"

  if [[ ! -f "$font_path" ]]; then
    log_error "Font not found: $font_path"
    return 1
  fi

  log_info "Removing font: $font_name"

  if [[ "$scope" == "system" ]]; then
    sudo rm "$font_path"
  else
    rm "$font_path"
  fi

  if [[ $? -eq 0 ]]; then
    log_info "Successfully removed: $font_name"
    refresh_font_cache
    return 0
  else
    log_error "Failed to remove: $font_name"
    return 1
  fi
}

# Function to check font installation requirements
check_font_requirements() {
  case "$(detect_platform)" in
    fedora|gnu)
      if ! command_exists fc-cache; then
        log_warn "fontconfig not installed. Installing..."
        if command_exists dnf; then
          sudo dnf install -y fontconfig
        elif command_exists apt-get; then
          sudo apt-get install -y fontconfig
        else
          log_error "Cannot install fontconfig automatically"
          return 1
        fi
      fi
      ;;
  esac
  return 0
}

# Export functions for use in other modules
export -f get_font_directory validate_font install_font install_fonts_from_directory
export -f refresh_font_cache list_installed_fonts install_repo_fonts install_font_family
export -f remove_font check_font_requirements
