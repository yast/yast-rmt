#
# spec file for package yast2-rmt
#
# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           yast2-rmt
Version:        1.2.2
Release:        0
Summary:        YaST2 - Module to configure RMT
License:        GPL-2.0-only
Group:          System/YaST
Url:            https://github.com/yast/yast-rmt

Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-devtools
BuildRequires:  yast2-ruby-bindings
#for install task
BuildRequires:  rubygem(yast-rake)
# for tests
BuildRequires:  rubygem(rspec)

Requires:       rmt-server >= 1.0.6
Requires:       yast2
Requires:       yast2-ruby-bindings

BuildArch:      noarch

%description
Provides the YaST module to configure the Repository Mirroring Tool (RMT) Server.

%prep
%setup -q

%check
%yast_check

%build

%install
%yast_install
%yast_metainfo

%files
%{yast_clientdir}
%{yast_libdir}
%{yast_desktopdir}
%{yast_metainfodir}
%{yast_ydatadir}
%license COPYING
%doc README.md

%changelog
