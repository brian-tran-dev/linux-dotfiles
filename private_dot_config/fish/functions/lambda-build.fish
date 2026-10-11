function lambda-build
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap .
	zip function.zip bootstrap
	ls -l bootstrap function.zip
end
