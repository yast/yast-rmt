FROM yastdevel/ruby
RUN gem install --no-rdoc --no-ri scc-codestyle
RUN rm /etc/alternatives/rubocop && ln -s /usr/lib64/ruby/gems/2.5.0/gems/rubocop-0.52.1/bin/rubocop /etc/alternatives/rubocop
COPY . /usr/src/app
