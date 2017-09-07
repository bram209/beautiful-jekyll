---
layout: post
title: A better alternative to Adblock Plus
subtitle: Or is an adblocker the best solution after all?
image: /img/adblock-logo.png
---

I have been using AdBlock Plus for years now. After reinstalling my desktop recently, I decided to try something else. We can alter the `hosts` file on our PC to blacklist domains. In this blog post I will briefly explain how both of these work and which one might be the best solution to an ad free internet experience.

## Table of contents
{:.no_toc}

{:toc headers: ['h1']}
* TOC

## How do ad blockers work?
Adblockers filter out unwanted content. These filter rules decide whether it should block/hide an ad or let it through.
All those filters come from huge lists, the main one being [EasyList](https://easylist.to/). You can specify your own filter rules as well or add another reputable source.

The adblocker compares every HTTP request with all the filter rules. If the URL of such request matches one of the filters, the request is blocked.

<div class="box-note" markdown="1">
**Pro's**
* Versatile, blocking based on URL paths and parameters
* UI interface (easily disable adblocker on specific sites)

**Con's**
* Slower than using a hosts file 
</div>

## The hosts file
A DNS (Domain Name System) translates IP addresses into something more memorable, a domain name. Normally, when you type in a web address, your PC will ping your DNS server to find out the TCP IP address of the server that you are trying to connect to. 

The `Hosts file` can be used to overwrite the DNS. 
Let's see how this works, before discussing why we would like to do this in the first place. We add a new domain filter by appending a new line to our hosts file in the following format: `IP DOMAIN`.

<div class="box-note" markdown="1">
**Pro’s**
* Faster as it blocks on full hostnames
* Native - Implemented by the OS in a low overhead language like C
* No more “Adblocker detected” messages
* Not limited to just browsers

**Con’s**
* Limited in capability
* Higher upkeep?
</div>

{:.no_toc}
### An example
When developing, we run our web apps locally. Let's say we grow tired of writing `localhost` all the time and are looking for a shorter alternative.
Let's add a new entry to our hosts file: 

```bash
sudo sh -c 'echo "127.0.0.1 localhost" >> /etc/hosts'
```
Note that we need permissions to the hosts file. We use the `-c` option so that our commands are read from a string. If we wouldn't do this, it will only execute the `echo` command with special privileges, but not redirecting/appending (`>>`) the output to the file. 

{: .box-note}
For Unix users, you can find the host file at `/etc/hosts`,<br />
and Windows users can find it at `C:\Windows\System32\drivers\etc\hosts`.

Now the domain name `local` will translate to our localhost's address `127.0.0.1`
![Example of altered hosts file](/img/hosts-file-example.png)
<br /><br />

## Blocking ads, trackers & malware
We can use this mechanism to our advantage by blocking ads. trackers & malware domains. Luckily there are some create reputable lists like [someonewhocares](http://someonewhocares.org/hosts/). 

We are going to use [hBlock](https://github.com/zant95/hBlock), a script that combines a few good lists together to create the perfect hosts file.
To install:

```bash
curl 'https://raw.githubusercontent.com/zant95/hblock/master/hblock' -o /tmp/hblock && \
  sudo mv /tmp/hblock /usr/local/bin/hblock && sudo chmod a+rx /usr/local/bin/hblock
 ```

 For fish shell users:
 ```bash
curl 'https://raw.githubusercontent.com/zant95/hblock/master/hblock' -o /tmp/hblock;  \
  sudo mv /tmp/hblock /usr/local/bin/hblock; sudo chmod a+rx /usr/local/bin/hblock
 ```

Now run it:
```bash
> hblock
 + Configuration: 
   - Hosts location: /etc/hosts
   - Redirection IP: 0.0.0.0
   - Backup: no
   - Lenient: no
   - Ignore download error: no
 + Downloading lists... 
 + Parsing lists... 
 + Generating hosts file... 
 + 75883 blacklisted domains! 
```

{: .box-note}
You might need to restart your network manager or clear the DNS cache. For restarting the manager in linux: `sudo systemctl restart NetworkManager.service`

## Automatically updating our hosts file
The domain lists that we talked about earlier, are updated daily. Therefore, we should update our hosts file daily as while.

Let's create an automatic task for this. You can create a [cronjob](https://en.wikipedia.org/wiki/Cron) for example, but since my distro uses `systemd`, I will create a [systemd timer](https://wiki.archlinux.org/index.php/Systemd/Timers).

We need to create 2 files: a `timer` and a `service`.
The service will execute the script and the timer is responsible for scheduling this task on a daily basis.

{% codeblock lang:bash /etc/systemd/system/hblock.timer %}
[Unit]
Description=Run hBlock daily

[Timer]
# On a daily basis
OnCalendar=daily 
Persistent=true     
# The service it has to execute
Unit=hblock.service 

[Install]
WantedBy=timers.target
{% endcodeblock %}

And the service:

{% codeblock lang:bash /etc/systemd/system/hblock.service %}
[Unit]
Description=Update hosts file to block ad, tracker & malware domains

[Service]
# do a single job and then exit
Type=oneshot 

# Path to executable
ExecStart=hblock 
{% endcodeblock %}

Note that you can place comments with the `#` prefix, but they **must be on a new line**. All we have to do now, is enabling the timer and we are good to go:

```bash
> systemctl enable hblock.timer 
Created symlink from /etc/systemd/system/timers.target.wants/hblock.timer to /etc/systemd/system/hblock.timer.
> systemctl list-timers --all
NEXT                          LEFT          LAST   PASSED     UNIT                         ACTIVATES
Fri 2017-09-08 00:00:00 CEST  2h 20min left n/a    n/a        hblock.timer                 hblock.service
```

## Verdict

In the end, the performance difference is probably negligible.
So if we ignore the performance difference, it basically comes down to 2 things:
* Which one blocks more ads
* Which one has the lowest upkeep

The hosts file blacklists an impressive 75883 domains and together with our daily scheduled update task, the upkeep for yourself will be zero. Now it all comes down to how up-to-date and reliable our sources are.

Everything considered this hosts file setup might work out well and is the speedier one of the two. It is not limited to browsers only and you will never get an "Adblocker detected" popup anymore. However, it is questionable how important this small gain in performance is. The safe choice would be to go with an adblocker, as it is more convenient to install and the most versatile of the two.