module github.com/seenem/auth-service

go 1.21

require (
	github.com/seenem/shared v0.0.0
	github.com/gorilla/mux v1.8.1
	github.com/golang-jwt/jwt/v4 v4.5.0
	golang.org/x/crypto v0.17.0
	github.com/go-playground/validator/v10 v10.16.0
	github.com/rs/cors v1.10.1
)

replace github.com/seenem/shared => ../shared
