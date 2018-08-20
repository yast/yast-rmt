# Copyright (c) 2018 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

NAME          = yast2-rmt
VERSION       = $(shell cat package/yast2-rmt.spec | sed -n 's/Version:\s*\t*\(.*\)/\1/p')

all:
	@:

clean:
	rm -rf package/*.tar.bz2
	rm -rf $(NAME)-$(VERSION)/

dist: clean
	@mkdir -p $(NAME)-$(VERSION)/
	@cp -r src $(NAME)-$(VERSION)/
	@cp README.md $(NAME)-$(VERSION)/
	@cp Gemfile $(NAME)-$(VERSION)/
	@cp Gemfile.lock $(NAME)-$(VERSION)/
	@cp COPYING $(NAME)-$(VERSION)/
	@cp RPMNAME $(NAME)-$(VERSION)/
	@cp Rakefile $(NAME)-$(VERSION)/

	find $(NAME)-$(VERSION) -name \*~ -exec rm {} \;
	tar cfvj package/$(NAME)-$(VERSION).tar.bz2 $(NAME)-$(VERSION)/
	rm -rf $(NAME)-$(VERSION)/

