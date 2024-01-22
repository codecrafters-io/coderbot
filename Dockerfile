FROM ruby:3.2.3

WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock

RUN bundle install

ADD . /app

EXPOSE 8080

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "8080"]
