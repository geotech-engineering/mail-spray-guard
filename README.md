# mail-spray-guard

Stop **password spraying** against your mail server (Dovecot + Postfix) with fail2ban — without locking out your own users.

Password-spraying botnets rotate through thousands of residential IP addresses and try **one password per mailbox per IP**.
The classic fail2ban rule ("5 failures in 10 minutes") never fires, because no single address ever fails 5 times.

mail-spray-guard adds two layers:

| Layer | Who | Rule | Ban |
|---|---|---|---|
| `mail-spray-guard` | addresses **outside your home countries** | **one** failed login | 30 days |
| `mail-spray-guard-home` | everyone else | 8 failures in 10 minutes | 1 hour, growing up to 1 week |

Addresses that **logged in successfully** in the last 14 days from a home country are never banned, so a user who mistypes a password at the office is safe.
A stolen password used from abroad does not make that address "good" — only home-country successes count.

Why it works: real users of a regional business log in from a few countries. Attackers come from everywhere.
One failed attempt from a country your users are never in is already a strong signal.

Background and the real incident this came from: **[Password spraying through residential proxies — what it looked like on a small business mail server](https://geotech.dev/engineering/password-spraying-residential-proxies-smb-email/?utm_source=github)**

## Requirements

- fail2ban 0.11+
- Dovecot and/or Postfix logging to one file (default `/var/log/maillog`; Debian/Ubuntu: `/var/log/mail.log`)
- `mmdblookup` (package `libmaxminddb` / `mmdb-bin`) and a country database in MaxMind format
  (GeoLite2-Country, or the free DB-IP Lite country database)

## Install

```bash
git clone https://github.com/geotech-dev/mail-spray-guard.git
cd mail-spray-guard
sudo cp mail-spray-guard.conf.example /etc/mail-spray-guard.conf   # then edit HOME_COUNTRIES
sudo ./install.sh
```

Test the filter against your own log first:

```bash
fail2ban-regex /var/log/maillog /etc/fail2ban/filter.d/mail-spray-guard.conf
fail2ban-regex tests/sample.log "$PWD/filter.d/mail-spray-guard.conf"   # 4 of 6 lines match (the 2 successful logins must not)
```

## Settings (`/etc/mail-spray-guard.conf`)

| Setting | Default | Meaning |
|---|---|---|
| `HOME_COUNTRIES` | `EG` | space-separated ISO codes where your users really are |
| `GEOIP_DB` | `/usr/share/GeoIP/GeoLite2-Country.mmdb` | country database |
| `DAYS` | `14` | how long a successful login keeps an address "known good" |
| `ALWAYS_IGNORE` | `127.0.0.1/8 ::1` | your server, office static IPs, monitoring |
| `MAILLOG` | `/var/log/maillog` | mail log |

To protect only some domains on a shared server, edit `_domain` in `filter.d/mail-spray-guard.conf`.

## Things to know

- **Travelling users**: one wrong password from abroad bans that address for 30 days. Unban with
  `fail2ban-client set mail-spray-guard unbanip <ip>`, or add their country to `HOME_COUNTRIES`.
- **Unknown country** (address not in the database): not banned on a single attempt; the home jail still applies.
- **Webmail** logs in from `127.0.0.1` — keep it in `ALWAYS_IGNORE`, and protect the webmail login separately.
- This stops the guessing. It does not replace strong unique passwords, and it does not help if a password is already stolen —
  watch for successful logins from new countries too.

## Licence

MIT — made by [GeoTech](https://geotech.dev/?utm_source=github). Questions and pull requests welcome.
