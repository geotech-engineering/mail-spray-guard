#!/bin/bash
# Install mail-spray-guard. Run as root from the repository folder.
# Safe to re-run. Does not touch your existing fail2ban jails.
set -euo pipefail
cd "$(dirname "$0")"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1 ($2)"; exit 1; }; }
need fail2ban-client "install fail2ban"
need mmdblookup "install libmaxminddb / mmdb-bin"

install -m 0644 filter.d/mail-spray-guard.conf /etc/fail2ban/filter.d/mail-spray-guard.conf
install -m 0644 jail.d/mail-spray-guard.local  /etc/fail2ban/jail.d/mail-spray-guard.local
install -m 0755 bin/msg-ignore-home /usr/local/sbin/msg-ignore-home
install -m 0755 bin/msg-goodips     /usr/local/sbin/msg-goodips
install -m 0644 cron.d/mail-spray-guard /etc/cron.d/mail-spray-guard
[ -e /etc/mail-spray-guard.conf ] || install -m 0644 mail-spray-guard.conf.example /etc/mail-spray-guard.conf

# shellcheck disable=SC1091
. /etc/mail-spray-guard.conf
[ -r "${GEOIP_DB:-/usr/share/GeoIP/GeoLite2-Country.mmdb}" ] || echo "WARNING: country database not found at ${GEOIP_DB:-/usr/share/GeoIP/GeoLite2-Country.mmdb}"

/usr/local/sbin/msg-goodips
echo "Check the filter against your log before enabling:"
echo "  fail2ban-regex ${MAILLOG:-/var/log/maillog} /etc/fail2ban/filter.d/mail-spray-guard.conf"
fail2ban-client reload
fail2ban-client status mail-spray-guard
