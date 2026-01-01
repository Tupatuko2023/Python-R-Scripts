#!/usr/bin/env bash
set -euo pipefail

E_OK=0
E_NET_DISABLED=10
E_NET_FAIL=20

echo "== diag_network_github =="
echo "timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "cwd: $(pwd)"

is_sensitive_name() {
  printf "%s" "$1" | grep -Eiq '(TOKEN|SECRET|KEY|PASS|PASSWORD|AUTH|COOKIE|CRED|SESSION)'
}

echo
echo "== env var names (no values; sensitive names redacted) =="
while IFS='=' read -r name _; do
  if is_sensitive_name "${name}"; then
    echo "REDACTED_ENV_NAME"
  else
    echo "${name}"
  fi
done < <(env) | sort -u

echo
echo "== proxy vars (values redacted) =="
for v in HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY; do
  val="${!v-}"
  if [ -z "${val}" ]; then
    echo "${v}=EMPTY"
  elif printf "%s" "${val}" | grep -q "@"; then
    echo "${v}=SET (redacted)"
  else
    echo "${v}=SET"
  fi
done

echo
echo "== tool availability =="
for cmd in curl openssl nslookup dig gh; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "${cmd}=present"
  else
    echo "${cmd}=missing"
  fi
done

net_disabled=0
if env | cut -d= -f1 | grep -q '^CODEX_SANDBOX_NETWORK_DISABLED$'; then
  net_disabled=1
fi
if env | cut -d= -f1 | grep -q '^SBX_NONET_ACTIVE$'; then
  net_disabled=1
fi

if [ "${net_disabled}" -eq 1 ]; then
  echo
  echo "== network policy =="
  echo "network_disabled=1 (CODEX_SANDBOX_NETWORK_DISABLED or SBX_NONET_ACTIVE present)"
fi

run_curl_head() {
  local url="$1"
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl=missing url=${url}"
    return 0
  fi
  set +e
  out=$(curl -I -sS --connect-timeout 3 --max-time 6 "${url}" 2>&1)
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "curl_error rc=${rc} url=${url} err=${out}"
  else
    code=$(printf "%s" "${out}" | head -n 1 | awk '{print $2}')
    echo "curl_ok url=${url} status=${code}"
  fi
}

if [ "${RUN_NETWORK_TESTS-}" != "1" ]; then
  echo
  echo "== network tests skipped =="
  echo "set RUN_NETWORK_TESTS=1 to run DNS/TLS/HTTP checks"
  if [ "${net_disabled}" -eq 1 ]; then
    exit "${E_NET_DISABLED}"
  fi
  exit "${E_OK}"
fi

dns_fail=0
tls_fail=0

echo
echo "== DNS test (opt-in) =="
if command -v nslookup >/dev/null 2>&1; then
  set +e
  nslookup api.github.com
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    dns_fail=1
  fi
elif command -v dig >/dev/null 2>&1; then
  set +e
  dig +short api.github.com
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    dns_fail=1
  fi
else
  echo "dns_tool=missing"
fi

echo
echo "== connectivity smoke tests (no auth, opt-in) =="
for url in \
  "https://example.com" \
  "https://example.org" \
  "https://example.net" \
  "https://httpbin.org/get" \
  "https://ifconfig.me" \
  "https://api.github.com" \
  "https://github.com" \
  "https://raw.githubusercontent.com" \
  "https://objects.githubusercontent.com" \
  "https://uploads.githubusercontent.com" \
  "https://api.github.com/rate_limit" \
  "https://api.github.com/octocat"
do
  run_curl_head "${url}"
done

echo
echo "== optional repo-scoped Actions API check (no auth by default) =="
if [ -n "${GITHUB_REPO-}" ]; then
  run_curl_head "https://api.github.com/repos/${GITHUB_REPO}/actions/runs?per_page=1"
  echo "note: set GITHUB_REPO=owner/repo to enable"
else
  echo "GITHUB_REPO not set; skipping repo-scoped check"
fi

echo
echo "== TLS handshake (opt-in) =="
if command -v openssl >/dev/null 2>&1; then
  set +e
  echo | openssl s_client -servername api.github.com -connect api.github.com:443 -brief 2>&1 | head -n 40
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    tls_fail=1
  fi
else
  echo "openssl=missing"
fi

if [ "${net_disabled}" -eq 1 ]; then
  exit "${E_NET_DISABLED}"
fi
if [ "${dns_fail}" -ne 0 ] || [ "${tls_fail}" -ne 0 ]; then
  exit "${E_NET_FAIL}"
fi
exit "${E_OK}"
