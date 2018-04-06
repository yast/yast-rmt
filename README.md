# yast2-rmt

[![Coverage Status](https://coveralls.io/repos/github/SUSE/yast2-rmt/badge.svg?branch=master)](https://coveralls.io/github/SUSE/yast2-rmt?branch=master)
[![Build Status](https://travis-ci.org/SUSE/yast2-rmt.svg?branch=master)](https://travis-ci.org/SUSE/yast2-rmt)
[![Maintainability](https://api.codeclimate.com/v1/badges/672b5ba57176d8b4be53/maintainability)](https://codeclimate.com/github/SUSE/yast2-rmt/maintainability)

Provides the YaST module to configure the Repository Mirroring Tool ([RMT](https://github.com/SUSE/rmt)) Server.

## Development

First read the excellent tutorial [:green_book: Creating the YaST journalctl module](http://yast.opensuse.org/yast-journalctl-tutorial/) to learn the basics about YaST module development.

### Running the module

`yast2-ruby-bindings` RPM package is not available as a gem, Yast runs on the system-wide Ruby interpreter only.

There different ways to run the module:

* `rake run` — by default starts Qt interface if it is available;
* `Y2DIR=src/ /usr/sbin/yast2 rmt` — same as above;
* `DISPLAY= rake run` — forces to run in ncurses mode;
* `Y2DIR=src/ /usr/sbin/yast2 --ncurses rmt` — same as above.

### Running tests

It is possible to run the specs in a Docker container:

```
docker build -t yast-rmt-image .
docker run -it yast-rmt-image rspec
```

### Package 

The package gets built for SLE 15 and openSUSE Leap 15 here: 
https://build.opensuse.org/package/show/systemsmanagement:SCC:RMT/yast2-rmt


#### Submit Requests to openSUSE Factory and SLES

To get a maintenance request accepted, each changelog entry needs to reference a bug or feature
request with `bsc#123` or `fate#123`.

##### Factory First

To submit a request to openSUSE Factory, issue this commands in the console:

```bash
osc sr systemsmanagement:SCC:RMT yast2-rmt openSUSE:Factory --no-cleanup
```


##### Internal Build Service

To make the initial submit for a new SLES version:

```bash
osc -A https://api.suse.de sr Devel:SCC:RMT yast2-rmt SUSE:SLE-15:GA --no-cleanup
```

To submit the updated package as a maintenance update to released SLES versions:

```bash
osc -A https://api.suse.de mr Devel:SCC:RMT yast2-rmt SUSE:SLE-12-SP2:Update --no-cleanup
osc -A https://api.suse.de mr Devel:SCC:RMT yast2-rmt SUSE:SLE-12-SP3:Update --no-cleanup
```

You can check the status of your requests [here](https://build.opensuse.org/package/requests/systemsmanagement:SCC:RMT/yast2-rmt) and [here](https://build.suse.de/package/requests/Devel:SCC:RMT/yast2-rmt).

After your requests got accepted, they still have to pass maintenance testing before they get released to customers. You can check their progress at [maintenance.suse.de](https://maintenance.suse.de/search/?q=yast2-rmt). If you still need help, the maintenance team can be reached at [maint-coord@suse.de](maint-coord@suse.de) or #maintenance on irc.suse.de.





