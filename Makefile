
all:
	@echo 'publish-www => Sends www to server'

publish-www:
	rsync -aASPvz --exclude=*~ --delete-excluded --delete-after www/ ambs@da.zbr.pt:/home/ambs/dic-aberto-www/

