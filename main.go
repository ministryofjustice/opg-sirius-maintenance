package main

import (
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	port := "8080"

	if value := os.Getenv("PORT"); value != "" {
		port = value
	}

	http.HandleFunc("/main.css", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "./static/main.css")
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)

		data, err := os.ReadFile("./static/index.html")

		var writeErr error

		if err != nil {
			_, writeErr = w.Write([]byte("Sirius is currently unavailable"))
		} else {
			w.Header().Set("Content-Type", "text/html")
			_, writeErr = w.Write(data)
		}

		if writeErr != nil {
			log.Printf("Error when writing response: %s", writeErr)
		}
	})

	http.HandleFunc("/health-check", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)

		_, writeErr := w.Write([]byte("Sirius maintenance healthy"))
		if writeErr != nil {
			log.Printf("Error when writing response: %s", writeErr)
		}
	})

	server := &http.Server{
		Addr:              ":" + port,
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("Running on port %s", port)
	log.Fatal(server.ListenAndServe())
}
