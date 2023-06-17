# Virus scanning

We use ClamAV to scan for viruses in uploaded bulk submission files. Regardless of if a file is found to contain a virus or not the result of the scan is recorded in the database for auditing purposes.

## Configuration

### Hosted enviroments (uat, staging and production)
In production we use a container within each App kubernetes pod that has a docker image with clamav installed. The web App pod has clamav "client", `clamav-daemon`, installed via the Dockerfile. There is a configuration file `clamd.container.conf` that opens the clamav container's port, 3310, on localhost, thus allowing the "client" to communicate with the container.

### Testing on CI
The test job uses a clamav "service" built from the same docker image used by hosted environment clamav containers. The service opens ports 3310 for internal/localhost use. In addition there is a step to install the `clamdscan` tool [could we just install this, instead of `clamav-daemon` in hosted environments too?!] in the test container. This allows the test run container to communicate with the clamav service container, to enable test examples to scan actual files.

Tests that really scan a file are [must be] marked `scan_with_clamav: true`. All other test's stub any calls to the scanner for speed purposes.

### Testing locally
see [local setup](#local-setup)

## Local setup

Executing `bin/setup` should already have installed clamav for local development and test. You can run the clamav installer for mac in isolation using `bin/install_clamav_on_mac`. This should also work on M1 Macs.

There may be additional configuration needed if tests marked `scan_with_clamav: true` fail.

### Trouble shooting failing clamav reliant tests
Check open ports return something like below

```sh
sudo lsof -PiTCP -sTCP:LISTEN | grep clamd
=>
clamd     76965          root    6u  IPv6 0xcefaa303d8212407      0t0  TCP localhost:3310 (LISTEN)
clamd     76965          root    7u  IPv4 0xcefaa308a8c5b167      0t0  TCP localhost:3310 (LISTEN)
```

If not then check your local `clamd.conf`
```sh
cat $(brew --prefix)/etc/clamav/clamd.conf | grep TCP
=>
# TCP port address.
TCPSocket 3310
# TCP address.
TCPAddr localhost
```

If these are commented out or do not match then edit the file to apply these changes. Once amended you will need to restart clamav

```sh
# list launchctl clamav items
sudo launchctl list | grep clam

# restart (stop and start)
sudo launchctl unload /Library/LaunchDaemons/clamav.clamd.plist
sudo launchctl load /Library/LaunchDaemons/clamav.clamd.plist
```
