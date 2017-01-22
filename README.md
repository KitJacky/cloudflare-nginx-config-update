# Cloudflare-Nginx

==============

Small script to automatically update Cloudflare's public IPs in your nginx configuration.
You can schedule it with cron.

Current version is in beta stage!

Roughly it generates a similar output like this:
https://support.cloudflare.com/hc/en-us/articles/200170706-How-do-I-restore-original-visitor-IP-with-Nginx-
It uses these source urls: https://www.cloudflare.com/ips/

You have to enable this nginx module as well:
http://nginx.org/en/docs/http/ngx_http_realip_module.html

### Synopsis
    
    cloudflare-nginx    [OPTIONS] [target]

### Options, Arguments

`target` is the name of the nginx configration snippet file. Its default value is `/etc/nginx/conf.d/cloudflare.conf`.

* `-c` Using CF-Connecting-IP header instead of the default X-Forwarded-For.
* `-4` Disabling IPV4 IPs.
* `-6` Disabling IPV6 IPs.
* `-x` Disabling real_ip_header directive.
* `-r` Real run mode: Overwrite the original file.
* `-s` Shows the difference between the original file and the newly generated one.
* `-n` Disabling backups. (By default he original file is saved with a `.bak` suffix.)
* `-d` Debug mode: shows the core logic's all steps.
* `-q` Quiet mode: suppress most of the output. (Arguments are processed in order of appearance, Previous argument's processing messages won't be suppressed. Move this to the first place if you want to suppress everything.)
* `-h` Help. Displays this page.

### Sample usages

By default nothing important will happen

    $ cloudflare-nginx.sh

Showing the potential changes

    $ cloudflare-nginx -s

A standard usage:

    $ cloudflare-nginx -sr

If you have logcheck or anything similar enabled, you may want to suppress the less interesting outputs:

    $ cloudflare-nginx -qr

### Dependencies

* Nginx realip module: http://nginx.org/en/docs/http/ngx_http_realip_module.html
* bash
* wget
* cp
* diff (for showing the diff)

### Author

Veres Lajos

### Original source

https://github.com/vlajos/cloudflare-nginx

Feel free to use!
