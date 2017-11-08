# Ansible Redis

* For multiple redis instance setups
* Installs redis30u from IUS repo
* Supports RHEL 6 / 7

## Example Usage

* Prod triple-redis setup:

        - { role: redis, redis_instance: { name: obj, port: 6379 }}
        - { role: redis, redis_instance: { name: fpc, port: 6381 }}
        - { role: redis, redis_instance: { name: ses, port: 6380, save: yes }}

* Stage triple-redis setup:

        - { role: redis, redis_instance: { name: stage-obj, port: 6389 }}
        - { role: redis, redis_instance: { name: stage-fpc, port: 6391 }}
        - { role: redis, redis_instance: { name: stage-ses, port: 6390, save: yes }}

* Customized Instance Configs

    Change the package name used to check the state of redis being installed
    
        redis_package_name: redis

    Set group vars to override the defaults and supply maxmemory-policy in the instance config instead of the base config.
    
        # Key/value hash of settings for /etc/redis-{{ redis_instance.name }}.conf
        redis_instance_config:
          - maxmemory-policy: "volatile-lru"

        # Key/value hash of settings for /etc/redis-base.conf
        redis_config:
          - daemonize: "yes"
          - timeout: "0"
          - loglevel: "notice"
          - databases: "2"
          - rdbcompression: "no"
          - dbfilename: "dump.rdb"
          - appendonly: "no"
          - appendfsync: "everysec"
          - no-appendfsync-on-rewrite: "no"
          - slowlog-log-slower-than: "10000"
          - slowlog-max-len: "1024"
          - list-max-ziplist-entries: "512"
          - list-max-ziplist-value: "64"
          - set-max-intset-entries: "512"
          - zset-max-ziplist-entries: "128"
          - zset-max-ziplist-value: "64"
          - activerehashing: "yes"
          - slave-serve-stale-data: "yes"
          - auto-aof-rewrite-percentage: "100"
          - auto-aof-rewrite-min-size: "64mb"
          - tcp-backlog: "511"
          - tcp-keepalive: "0"
          - repl-disable-tcp-nodelay: "no"
    
    Then when calling the role, specify the instance config value per role where it needs to be different

        - { role: redis, redis_instance: { name: obj, port: 6379 }, redis_maxmemory: 8gb, redis_instance_config: [{maxmemory-policy: allkeys-lru}] }
        - { role: redis, redis_instance: { name: fpc, port: 6381 }, redis_maxmemory: 8gb, redis_instance_config: [{maxmemory-policy: allkeys-lru}] }
        - { role: redis, redis_instance: { name: ses, port: 6380, save: yes }, redis_maxmemory: 8gb}
