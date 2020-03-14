
all:
	@echo 'publish-www => Sends www to server'

publish-www: www/css/da.css publish-resources
	rsync -aASPvz --exclude=*~ --exclude=resources --delete-after www/ ambs@da.zbr.pt:/home/ambs/dic-aberto-www/

www/css/da.css: www/css/da.scss
	sass www/css/da.scss > www/css/da.css

publish-resources:
	rsync -aASPvz --exclude=*~ --delete-after Resources/ ambs@da.zbr.pt:/home/ambs/dic-aberto-www/resources/


