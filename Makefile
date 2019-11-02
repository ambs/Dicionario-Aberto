
all:
	@echo 'publish-www => Sends www to server'

publish-www:
	rsync -aASPvz www/ ambs@bottle.zbr.pt:/home/ambs/dic-aberto-www/

