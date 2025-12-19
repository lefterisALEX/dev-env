
#!/usr/bin/env bash
set -u

STATUS_OK="OK"
STATUS_MISSING="MISSING"

ok_count=0
missing_count=0

print_header() {
  echo "=============================================="
  echo " Dev Environment Tooling Overview"
  echo "=============================================="
  printf "%-15s %-10s %s\n" "TOOL" "STATUS" "VERSION / INFO"
  echo "----------------------------------------------"
}

print_row() {
  local tool="$1"
  local status="$2"
  local info="$3"

  printf "%-15s %-10s %s\n" "$tool" "$status" "$info"
}

check_tool() {
  local name="$1"
  local cmd="$2"
  local version_cmd="${3:-}"

  if command -v "$cmd" >/dev/null 2>&1; then
    ok_count=$((ok_count + 1))
    if [[ -n "$version_cmd" ]]; then
      local version
      version="$($version_cmd 2>/dev/null | head -n1 || echo "unknown")"
      print_row "$name" "$STATUS_OK" "$version"
    else
      print_row "$name" "$STATUS_OK" "-"
    fi
  else
    missing_count=$((missing_count + 1))
    print_row "$name" "$STATUS_MISSING" "-"
  fi
}

print_header

# ---- shell / core ----
check_tool "fish" fish "fish --version"
check_tool "git" git "git --version"
check_tool "curl" curl "curl --version"
check_tool "jq" jq "jq --version"
check_tool "tmux" tmux "tmux -V"
check_tool "ssh" ssh "ssh -V"
check_tool "fzf" fzf "fzf --version"
check_tool "bat" bat "bat --version"
check_tool "fd" fd "fd --version"

# ---- navigation ----
check_tool "zoxide" zoxide "zoxide --version"
check_tool "direnv" direnv "direnv --version"

# ---- editors ----
check_tool "neovim" nvim "nvim --version"

# ---- languages ----
check_tool "python3" python3 "python3 --version"
check_tool "pip" pip3 "pip3 --version"
check_tool "node" node "node --version"
check_tool "npm" npm "npm --version"
check_tool "go" go "go version"

# ---- kubernetes ----
check_tool "kubectl" kubectl "kubectl version --client --short"
check_tool "helm" helm "helm version --short"
check_tool "stern" stern "stern --version"
check_tool "kubie" kubie "kubie --version"
check_tool "crane" crane "crane version"

# ---- misc ----
check_tool "lazygit" lazygit "lazygit --version"
check_tool "eza" eza "eza --version"
check_tool "ripgrep" rg "rg --version"
check_tool "starship" starship "starship --version"

echo "----------------------------------------------"
echo " Installed : $ok_count"
echo " Missing   : $missing_count"
echo "----------------------------------------------"
echo "ℹ️  This is an informational report only."
echo "ℹ️  No failures are triggered by missing tools."
echo

exit 0
