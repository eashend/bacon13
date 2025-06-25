module github.com/bacon13/auth-service

go 1.21

require (
	github.com/bacon13/shared v0.0.0
	github.com/go-playground/validator/v10 v10.16.0
	github.com/gorilla/mux v1.8.1
	github.com/rs/cors v1.10.1
)

require (
	github.com/gabriel-vasile/mimetype v1.4.2 // indirect
	github.com/go-playground/locales v0.14.1 // indirect
	github.com/go-playground/universal-translator v0.18.1 // indirect
	github.com/leodido/go-urn v1.2.4 // indirect
	golang.org/x/net v0.10.0 // indirect
	golang.org/x/sys v0.15.0 // indirect
	golang.org/x/text v0.14.0 // indirect
)

replace github.com/bacon13/shared => ../shared
