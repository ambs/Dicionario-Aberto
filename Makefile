
all:
	@echo 'publish-www => Sends www to server'

deploy:
	rsync -aASPz --delete-after --exclude=logs/ --exclude=.local API/ da.zbr.pt:/home/ambs/dic-aberto-api/
	scp API/myconfig.yml da.zbr.pt:/home/ambs/dic-aberto-api/config.yml
	ssh da.zbr.pt 'cd /home/ambs/dic-aberto-api && pwd && PERL_USE_UNSAFE_INC=1 p5stack setup'
	ssh da.zbr.pt 'cd /home/ambs/dic-aberto-api && p5stack cpanm Dist::Zilla'
	rsync -aASPvz --exclude .build DA-Database/ da.zbr.pt:/home/ambs/dic-aberto-api/DA-Database/
	ssh da.zbr.pt 'cd /home/ambs/dic-aberto-api/DA-Database;  dzil build; mv -v *.tar.gz ..; cd ..; p5stack cpanm *.tar.gz; rm -fr DA-Database*'

publish-www: www/css/da.css publish-resources
	rsync -aASPvz --exclude=*~ --exclude=resources --delete-after www/ ambs@da.zbr.pt:/home/ambs/dic-aberto-www/

www/css/da.css: www/css/da.scss
	sass www/css/da.scss > www/css/da.css

publish-resources:
	rsync -aASPvz --exclude=*~ --delete-after Resources/ ambs@da.zbr.pt:/home/ambs/dic-aberto-www/resources/


