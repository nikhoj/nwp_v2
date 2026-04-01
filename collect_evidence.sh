#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WPS_DIR="${ROOT}/WPS-4.5"
EM_REAL_DIR="${ROOT}/WRFV4.5.2/test/em_real"

LOG_DIR="${ROOT}/logs"
META_DIR="${ROOT}/results/meta"
FIG_DIR="${ROOT}/results/figures"

mkdir -p "${LOG_DIR}" "${META_DIR}" "${FIG_DIR}"

now_utc="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

{
  echo "timestamp_utc=${now_utc}"
  echo "host=$(hostname)"
  echo "user=$(whoami)"
  echo "root=${ROOT}"
  if command -v git >/dev/null 2>&1; then
    echo "git_commit=$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    echo "git_status=$(git -C "${ROOT}" status --short | wc -l | tr -d ' ') changes"
  fi
} > "${META_DIR}/run_info.txt"

if [[ -f "${WPS_DIR}/metgrid.log" ]]; then
  {
    echo "# metgrid tail"
    echo "# generated ${now_utc}"
    tail -n 40 "${WPS_DIR}/metgrid.log"
  } > "${LOG_DIR}/metgrid_success.txt"
fi

if [[ -f "${EM_REAL_DIR}/rsl.error.0000" ]]; then
  {
    echo "# real success grep"
    echo "# generated ${now_utc}"
    grep -n "SUCCESS COMPLETE REAL_EM INIT" "${EM_REAL_DIR}/rsl.error.0000" || true
  } > "${LOG_DIR}/real_success.txt"
fi

if [[ -f "${EM_REAL_DIR}/rsl.error.0000" ]]; then
  {
    echo "# wrf rsl.error tail"
    echo "# generated ${now_utc}"
    tail -n 120 "${EM_REAL_DIR}/rsl.error.0000"
  } > "${LOG_DIR}/wrf_tail.txt"
fi

: > "${META_DIR}/checksums.sha256"
for f in \
  "${EM_REAL_DIR}/wrfinput_d01" \
  "${EM_REAL_DIR}/wrfbdy_d01" \
  "${EM_REAL_DIR}"/wrfout_d01_* \
  "${WPS_DIR}"/met_em.d01.*.nc
  do
  if [[ -f "$f" ]]; then
    sha256sum "$f" >> "${META_DIR}/checksums.sha256"
  fi
done

if command -v ncdump >/dev/null 2>&1; then
  first_met_em="$(ls -1 "${WPS_DIR}"/met_em.d01.*.nc 2>/dev/null | head -n 1 || true)"
  if [[ -n "${first_met_em}" ]]; then
    ncdump -h "${first_met_em}" > "${META_DIR}/met_em_header.txt"
  fi

  first_wrfout="$(ls -1 "${EM_REAL_DIR}"/wrfout_d01_* 2>/dev/null | head -n 1 || true)"
  if [[ -n "${first_wrfout}" ]]; then
    ncdump -h "${first_wrfout}" > "${META_DIR}/wrfout_header.txt"
  fi
fi

cat > "${LOG_DIR}/how_to_regenerate.txt" << EOT
Generated at: ${now_utc}
Command:
  bash collect_evidence.sh

This folder contains lightweight proof artifacts only.
Large model outputs remain outside Git.
EOT

echo "Evidence collection complete."
echo "Created: ${LOG_DIR} and ${META_DIR}"
