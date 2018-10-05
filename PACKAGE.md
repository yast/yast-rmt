## yast2-rmt Packaging

### Creating the tarball for packaging

To create the tarball for testing or packaing run:

```
rake package
```

### Package

The package gets built for SLE 15 and openSUSE Leap 15 here:
https://build.opensuse.org/package/show/systemsmanagement:SCC:RMT/yast2-rmt

You can use:

```bash
rake osc:commit
```

to commit the current version to OBS.


#### Submit Requests to openSUSE Factory and SLES

To get a maintenance request accepted, each changelog entry needs to have at
least one reference to a bug or feature request like `bsc#123` or `fate#123`.

Note: If you want to disable automatic changes made by osc (e.g. License string)
      use the `--no-cleanup` switch. Can be used with commands like `osc mr`, `osc sr`
      and `osc ci`.

##### Factory First

To submit a request to openSUSE Factory, issue this commands in the console:

```bash
osc sr systemsmanagement:SCC:RMT yast2-rmt openSUSE:Factory
```

##### Submit maintenance updates for SLES to the Internal Build Service

###### Get target codestreams where to submit

To check out which codestreams the package is currently maintained in, run:

```bash
osc -A https://api.suse.de maintained yast2-rmt
```

For a more detailed view which target codestreams are in which state, check out: [Codestream overview](https://maintenance.suse.de/maintained/?package=yast2-rmt)

###### Submit updates

For each maintained codestream you need to create a new maintenance request:

```bash
osc -A https://api.suse.de mr Devel:SCC:RMT yast2-rmt SUSE:SLE-15:Update
```

Note: In case the `mr` (maintenance request) command is not working properly,
      try `sr` (submit request) command.


Example:

```bash
$ osc -A https://api.suse.de maintained yast2-rmt
SUSE:SLE-15:Update/yast2-rmt

$ osc -A https://api.suse.de mr Devel:SCC:RMT yast2-rmt SUSE:SLE-15:Update
Using target project 'SUSE:Maintenance'
1736456
```

You can check the status of your requests [here](https://build.opensuse.org/package/requests/systemsmanagement:SCC:RMT/yast2-rmt) and [here](https://build.suse.de/package/requests/Devel:SCC:RMT/yast2-rmt).

After your requests have been accepted, they still have to pass maintenance testing before they are released to customers. You can check their progress at [maintenance.suse.de](https://maintenance.suse.de/search/?q=yast2-rmt). If you still need help, the maintenance team can be reached at [maint-coord@suse.de](maint-coord@suse.de) or #maintenance on irc.suse.de.
