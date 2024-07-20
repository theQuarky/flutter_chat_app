.PHONY: build build-FindMatchesFunction

build build-FindMatchesFunction:
	GOOS=linux GOARCH=amd64 go build -o bootstrap main.go
	cp bootstrap $(ARTIFACTS_DIR)
	cp firebase-service-account.json $(ARTIFACTS_DIR)