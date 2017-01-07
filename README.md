# haproxy-letsencrypt-scripts
A Small set of scripts to help Lets Encrypt play nicely with HAProxy.

## Installation
Clone this repository.

    git clone https://github.com/cypherlou/haproxy-letsencrypt-scripts.git

## Requirements
* Let's Encrypt binaries (letsencrypt >= 0.4.1)
* HAProxy (HA-Proxy >= 1.6.3)

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

## Notes
* Certs are validated before being copied to the destination directory (`HAPROXY_CERT_DIR`).
* HAProxy is never restarted automatically by these scripts.
* Any script failure will result in an exit status of 2 so it is safe to chain commands with `&&`.
* The user running these scripts needs to have write access to `HAPROXY_CERT_DIR`.

## Resources
* [HAProxy](http://www.haproxy.org/)
* [Let's Encrypt](https://letsencrypt.org/)
* [Let's Encrypt on github](https://github.com/certbot/certbot)
