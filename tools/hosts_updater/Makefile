$(USERPROFILE)/go/bin/go-winres:
	go install github.com/tc-hib/go-winres@latest

tools: $(USERPROFILE)/go/bin/go-winres

.PHONY: build
build: tools
	$(USERPROFILE)/go/bin/go-winres make
	go build -ldflags="-s -w" .
