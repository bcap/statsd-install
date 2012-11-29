What
----

This is a automated installation of graphite (with whisper and carbon) + statsd using puppet on ubuntu 12.04

How
---

To run this installation just:

* clone the project:

		git clone https://github.com/bcap/statsd-install.git && cd statsd-install

* install vagrant if not installed or get a release at the [vagrant site](http://vagrantup.com/):

		gems install vagrant 

* run the vm 

		vagrant up

* access [localhost:8080](http://localhost:8080) for the graphs

* push data directly into carbon/graphite by `localhost:2003`. Example: 
		
		# set a metric called test.somemetic to value 100
		echo "test.somemetric 100 `date +%s`" | nc localhost 2003

* push data directly into statsd by `localhost:8125`. Example:

		# increase the test counter by 10
		echo -n "test:10|c" | nc -u localhost 8125

Why
---

Graphite in its current state involves a lot of manual work to install. As this forms a major barrier, automating the whole installation is a good idea.

This is a fork from a project that already did this, but it used 2 custom created deb files with no source code for generating them. Creating custom packages involves an extra effort on maintaining them. For this reason I wanted to avoid custom packages and created a fork where all the installation is done using packages from official sources

Who
---

Fork chain/credits:

[this project](https://github.com/bcap/statsd-install) <- [liuggio's vagrant-statsd-graphite-puppet](https://github.com/liuggio/vagrant-statsd-graphite-puppet) <- [Jimdo's vagrant-statsd-graphite-puppet](https://github.com/Jimdo/vagrant-statsd-graphite-puppet)
