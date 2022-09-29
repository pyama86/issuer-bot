registry   = pyama
repository = issuer-bot
image:
	git rev-parse HEAD > REVISION
	docker build --platform linux/amd64 -t $(registry)/$(repository):latest .
	docker push $(registry)/$(repository):latest
