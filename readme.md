## about

This is a simple sinatra project. SSO connect for provider system. Like  [kf5](http://www.kf5.com/v1api/single_sign_on/) ,etc.

## usage

* simple run:
```
bundle install  && ruby app.rb or rackup
```

* thin server run
```
mkdir -p tmp/pids tmp/sockets # create flold
thin -p 4567 -P tmp/pids/thin.pid -l logs/thin.log -d start
#or
thin start -C config/thin.yml
```