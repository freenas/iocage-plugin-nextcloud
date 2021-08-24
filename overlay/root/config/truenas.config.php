<?php
$CONFIG = array(
  'one-click-instance' => true,
  'one-click-instance.user-limit' => 100,
  'memcache.distributed' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
    'host' => 'localhost',
  ),
  'logfile' => '/var/log/nextcloud/nextcloud.log'
);