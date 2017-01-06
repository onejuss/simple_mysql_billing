# simple_mysql_billing
This is a simple mysql billing for sourcemod, i made it for my Private CSGO Servers

# add connection to simple_mysql_billing in your addons/sourcemod/configs/databases.cfg file
"mysql_simple_billing"
         {
                "driver"   "mysql"
                "host"   "your_ip_to_database"
                "database"   "the_name_of_database"
                "user"   "username_of_your_database"
                "pass"   "password_of_your_database"
        }

# create table 
CREATE TABLE `billing` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL DEFAULT '',
  `expire_date` date DEFAULT NULL,
  `joind_dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# change message to player on lines 80, 95 and 101 to your prefer in simple_mysql_billing.sp
line:80 - KickClient(client, "Welcome! This is a privet server, in order to play you have to subscribe http://yoursite.com");
line:95 - KickClient(client, "Sorry, your Subscriptions is ended %s http://yoursite.com", buffer);
line:101 - KickClient(client, "Welcome!!! This is a privet server, in order to play you have to subscribe http://yoursite.com");

# Compile simple_mysql_billing.sp here - https://www.sourcemod.net/compiler.php
it might throw warnings like this:
/groups/sourcemod/upload_tmp/textUfqL0Y.sp(79) : warning 217: loose indentation
/groups/sourcemod/upload_tmp/textUfqL0Y.sp(80) : warning 217: loose indentation 

but its ok 
