
all:
	@echo 'publish-www => Sends www to server'

publish-www: www/css/da.css
	rsync -aASPvz --exclude=*~ --delete-excluded --delete-after www/ ambs@da.zbr.pt:/home/ambs/dic-aberto-www/

www/css/da.css: www/css/da.scss
	sass www/css/da.scss > www/css/da.css

