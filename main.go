package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	port := "8080"

	if value := os.Getenv("PORT"); value != "" {
		port = value
	}

	http.Handle("/", http.FileServer(http.Dir("./static")))

	log.Fatal(http.ListenAndServe(":"+port, nil))
	log.Printf("Running on port %s", port)
}
