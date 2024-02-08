# yast2-rmt

[![Workflow Status](https://github.com/yast/yast-rmt/workflows/CI/badge.svg?branch=master)](
https://github.com/yast/yast-rmt/actions?query=branch%3Amaster)
[![Coverage Status](https://coveralls.io/repos/github/SUSE/yast2-rmt/badge.svg?branch=master)](https://coveralls.io/github/SUSE/yast2-rmt?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/672b5ba57176d8b4be53/maintainability)](https://codeclimate.com/github/SUSE/yast2-rmt/maintainability)

Provides the YaST module to configure the Repository Mirroring Tool ([RMT](https://github.com/SUSE/rmt)) Server.

## Development

First read the excellent tutorial [:green_book: Creating the YaST journalctl module](http://yast.opensuse.org/yast-journalctl-tutorial/) to learn the basics about YaST module development.

### Running the module

`yast2-ruby-bindings` RPM package is not available as a gem, YaST runs on the default system-wide Ruby interpreter only (available in the OSS repository).

There different ways to run the module:

* `rake run` — by default starts Qt interface if it is available;
* `Y2DIR=src/ /usr/sbin/yast2 rmt` — same as above;
* `DISPLAY= rake run` — forces to run in ncurses mode;
* `Y2DIR=src/ /usr/sbin/yast2 --ncurses rmt` — same as above.

#### Docker Setup

To run the module within a Docker container:

1. Select a proper Docker container image for YaST from https://registry.opensuse.org, according to the branch, e.g.:

   * On branch `master`, use `yast/head/containers_tumbleweed/yast-ruby`.
   * On branch `SLE-15-SP6`, use `yast/sle-15/sp6/containers/yast-ruby`.

2. Run the Docker container with access to the localhost network with the chosen distribution and version:

   ```shell
   docker run --network host -v "$(pwd):/usr/src/app" -w "/usr/src/app" -it registry.opensuse.org/yast/sle-15/sp6/containers/yast-ruby sh
   ```

3. On the container, install the `rmt-server` package:

   ```shell
   zypper --non-interactive install rmt-server
   ```

4. Run the YaST RMT module with `rake run` or through the other ways previously described.

### Running tests

It is possible to run the specs in a Docker container:

```shell
docker run -v "$(pwd):/usr/src/app" -w "/usr/src/app" -it registry.opensuse.org/yast/sle-15/sp6/containers/yast-ruby rake test:unit
```

### Resources

- [YaST Style Guide](https://en.opensuse.org/openSUSE:YaST_style_guide)
- [YaST Localization](https://yastgithubio.readthedocs.io/en/latest/localization/)
