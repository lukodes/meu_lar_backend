FROM gvn182/uccbase:276

EXPOSE 443
RUN mkdir -p /etc/clamav/qa
RUN mkdir -p /etc/clamav/prod
RUN mkdir -p /etc/clamav/dev

ADD clamd.remote.conf.prod /etc/clamav/prod/clamd.remote.conf
ADD clamd.remote.conf.qa /etc/clamav/qa/clamd.remote.conf
ADD clamd.remote.conf.verdecard /etc/clamav/verdecard/clamd.remote.conf
ADD clamd.remote.conf.dev_env /etc/clamav/dev/clamd.remote.conf

ADD nginx.conf /etc/nginx/nginx.conf
# RUN chown -R www-data:www-data /var/lib/nginx
ADD nginx-sites.conf /etc/nginx/sites-enabled/default

ENV PATH /opt/rubies/ruby-2.7.6/bin:$PATH

# Install Rails App
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN gem install bundler:2.3.20
RUN bundle install --without development test
ADD . /app
RUN cp config/database-sample.yml config/database.yml

# RUN npm --prefix agent-ui install agent-ui
# RUN npm --prefix agent-ui run build
# RUN rm -rf public/agent_ui/* && cp -a agent-ui/dist/. public/agent_ui/

# Add default unicorn config
ADD privkey.pem /etc/certs/privkey.pem
ADD fullchain.pem /etc/certs/fullchain.pem
ADD dhparam.pem /etc/certs/dhparam.pem
ADD openssl.cnf /etc/ssl/openssl.cnf

# RUN minify --recursive --type=css --match=\.css$ -o /app/public/ --verbose /app/public/
# RUN minify --recursive --type=js --match=\.js$ -o /app/public/ --verbose /app/public/
# ADD jquery.dataTables.css /app/public/datatables/media/css/jquery.dataTables.css

# Add default foreman config
RUN gem install foreman
ADD Procfile /app/Procfile
# RUN bundle exec whenever --update-crontab
CMD bundle exec rake db:migrate & whenever --update-crontab & foreman start -f Procfile
