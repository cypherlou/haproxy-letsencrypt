# haproxy-letsencrypt
A Small set of scripts to help Let's Encrypt play nicely with HAProxy. These are not unique or necessarily the best but work well in my standard distribution.

## Installation
Clone this repository.

    git clone https://github.com/cypherlou/haproxy-letsencrypt.git

## Requirements
* Ubuntu 16.04
* Let's Encrypt binaries (letsencrypt >= 0.4.1) `git clone https://github.com/letsencrypt/letsencrypt`
* HAProxy binaries (HA-Proxy >= 1.6.3)

## HAProxy configuration
The HAProxy configuration and these scripts assume your store your PEM files in `/etc/haproxy/certs`. If this is not the case then modify the below examples accordingly and update `HAPROXY_CERT_DIR` in `letsencrypt-config.sh`.

    global
        :
        ca-base       /etc/haproxy/certs
        crt-base      /etc/haproxy/certs
        ssl-default-bind-ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:RC4+SHA:HIGH:!MD5:!aNULL:!EDH:!RC4
        ssl-default-bind-options force-tlsv12 no-sslv3 no-tlsv10 no-tlsv11
        :

    frontend             public
        bind               :80
        bind               :443 ssl crt /etc/haproxy/certs
        :
        acl                is_letsencrypt_request path_beg -i /.well-known/acme-challenge/
        :
        use_backend        letsencrypt_backend if is_letsencrypt_request
        :

    backend            letsencrypt_backend
        server             letsencrypt 127.0.0.1:10000

If port `10000` is not available then modify this example making use of another port and then update `BASE_PORT` in `letsencrypt-config.sh`.

## Creating a new Certificate
To create a new certificate, run `letsencrypt-new.sh` with one or more domains. For example, to create a single PEM file with 2 certificates, one for my-domain.com and another for www<i></i>.my-domain.com, run the following command;

    letsencrypt-new.sh my-domain.com www.my-domain.com

## Creating a new Certificate
If you wish to see what domains are supported by any given `.pem` in the `HAPROXY_CERT_DIR` directory then make use of the `letsencrypt-dump.sh` script which accepts the name of the domain of interest to you. 

    letsencrypt-dump.sh telephone-number-checker.co.uk

    Certificates in /etc/haproxy/certs/telephone-number-checker.co.uk.pem;
    telephone-number-checker.co.uk
    www.telephone-number-checker.co.uk
    admin.telephone-number-checker.co.uk

## Domain renewal
To renew all Let's Encrypt Certificates run `letsencrypt-renew.sh`. This script will renew certs a required and then copy them into the cert directory defined by `HAPROXY_CERT_DIR`.

### Cron
To run the renewal script via crontab add something similar to the below example. Run the script once a week in line with Let's Encrypt's recommendations.

    0 5 * * 1 /bin/bash letsencrypt-renew.sh && service haproxy restart

**Notes**
* You will need to use the full path to the `letsencrypt-renew.sh` script.
* If `letsencrypt-renew.sh` fails then the restart will not be executed.
* This crontab user needs to be run by a user with rights to restart HAProxy.

### logrotated
To make use of the `letsencrypt-renew.sh` script from the log rotation daemon then add it as a `prerotate` task in the `/etc/logrotate.d/haproxy.conf` file.

    /var/log/haproxy.log {
      weekly
      rotate 52
      missingok
      notifempty
      compress
      delaycompress
      prerotate
          letsencrypt-renew.sh >/dev/null 2>&1 || true
      endscript
      postrotate
          invoke-rc.d rsyslog rotate >/dev/null 2>&1 || true
      endscript
    }

**Notes**
* You will need to use the full path to the `letsencrypt-renew.sh` script.
* The logrotate daemon user needs to have write access to `HAPROXY_CERT_DIR`.
* Depending on your Linux distribution or your HAProxy installation `/etc/logrotate.d/haproxy.conf` may not exist. Other options include;
  * Adding your own configuration to `rsyslogd` so that HAProxy produces its own log file. It may be that log data is being sent to `/var/log/syslog` or similar.
  * Add the `prerotate` option to rotate `/var/log/syslog` or equivalent file.

## Notes
* Certs are validated before being copied to the destination directory (`HAPROXY_CERT_DIR`).
* HAProxy is never restarted automatically by these scripts.
* Any script failure will result in an exit status of 2 so it is safe to chain commands with `&&`.
* The user running these scripts needs to have write access to `HAPROXY_CERT_DIR`.
* If let's Encrypt has not previously been run then it will be necessary to agree to Term & Conditions. It is possible to do this with `letsencrypt-auto certonly --standalone --agree-tos --email you-email@your-domain.com`. You can exit the process without generating a cert by entering `c` when the process asks for a domain name.

## Resources
* [HAProxy](http://www.haproxy.org/)
* [Let's Encrypt](https://letsencrypt.org/)
* [Let's Encrypt on github](https://github.com/certbot/certbot)

## Scope
This document is not intended to assist with the installation of any of the dependancies herein mentioned. The author is happy to answer questions at *cypherlou666 [at] gmail.com*.

## License
Copyright (c) 2017 Destar Limited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

## Disclaimer
The entire risk as to the quality and performance of the source code in this repository is borne by you.
