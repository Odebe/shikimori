[![CircleCI](https://circleci.com/gh/morr/shikimori.svg?style=svg&circle-token=5bd1a64ae9642ddb8d27a9585881756804ce9163)](https://circleci.com/gh/morr/shikimori)

## PostgreSQL
### DB
```shell
~ psql -d postgres
postgres=# create user shikimori_production;
postgres=# create user shikimori_test;
postgres=# alter user shikimori_production createdb;
postgres=# alter user shikimori_test createdb;
```


### Extensions
```shell
~ psql -d shikimori_test
shikimori_test=# CREATE EXTENSION unaccent;
```

```shell
~ psql -d shikimori_production
shikimori_production=# CREATE EXTENSION unaccent;
```

### Restore from backup
```shell
~ psql -U shikimori_production -d shikimori_production -f PostgreSQL.sql
```

## Start Service
```shell
~ brew install yarn
~ yarn install
~ cd ..
~ git clone git@github.com:shikimori/neko-achievements.git
~ git clone git@github.com:morr/camo.git
~ cd shikimori
~ brew install honcho # https://github.com/nickstenning/honcho
~ honcho start
```


## Update neko rules
```sh
rails neko:update
```


## Webpack debugger
https://nodejs.org/en/docs/inspector/
Install the Chrome Extension NIM (Node Inspector Manager): https://chrome.google.com/webstore/detail/nim-node-inspector-manage/gnhhdgbaldcilmgcpfddgdbkhjohddkj
```shell
RAILS_ENV=development NODE_ENV=development NODE_PATH=node_modules node --inspect node_modules/.bin/webpack-dev-server --progress --color --config config/webpack/development.js
```


## Webpack visualizer
https://chrisbateman.github.io/webpack-visualizer/


## Parse google spreadsheet achievements
```ruby
require 'smarter_csv'
File.open('/tmp/achievements.yml', 'w') {|f| f.write SmarterCSV.process(open('/tmp/achievements.csv')).to_yaml }
```

## Ban tor
```bash
sudo su
ipset -N tor2 iphash
wget -q "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=8.8.8.8" -O -|sed '/^#/d' |while read IP
do
  ipset -q -A tor2 $IP
done
# swap existing list to the new one
ipset swap tor tor2
ipset destroy tor2

sudo iptables -D INPUT -m set --match-set tor src -j DROP
sudo iptables -A INPUT -m set --match-set tor src -j DROP
```


## восстановление списка и истории пользователя
```ruby

# on local backup
user_id = 34852
puts UserRate.where(user_id: user_id).all.to_json;
puts UserHistory.where(user_id: user_id).all.to_json;

# on production
user_id = 34852
user_rates = [{"id":9844744,"user_id":34852,"target_id":16,"score":0,"status":"planned","episodes":0,"created_at":"2016-02-27T20:59:56.718+03:00","updated_at":"2016-02-27T20:59:56.718+03:00","target_type":"Anime","volumes":0,"chapters":0,"text":nil,"rewatches":0}]
user_histories = [{"id":8285220,"user_id":34852,"target_id":nil,"target_type":nil,"action":"registration","value":nil,"created_at":"2015-03-11T17:13:31.018+03:00","updated_at":"2015-03-11T17:13:31.018+03:00","prior_value":nil}]

UserRate.record_timestamps = false;
UserHistory.record_timestamps = false;

UserRate.where(user_id: user_id).delete_all;
UserHistory.where(user_id: user_id).delete_all;

UserRate.import user_rates.map {|v| UserRate.new(v) }.each { |v| v.run_callbacks(:save) { false }; v.run_callbacks(:create) { false }; };
UserHistory.import user_histories.map {|v| UserHistory.new(v) }.each { |v| v.run_callbacks(:save) { false }; v.run_callbacks(:create) { false }; };

User.find(user_id).touch; # for cache reset
```

