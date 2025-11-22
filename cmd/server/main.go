package main

import (
	"github.com/gin-gonic/gin"
	"github.com/snnyvrz/go-book-crud-gin/internal/db"
	"github.com/snnyvrz/go-book-crud-gin/internal/handler"
	"github.com/snnyvrz/go-book-crud-gin/internal/model"
)

func main() {
	e := gin.Default()

	e.SetTrustedProxies([]string{
		"127.0.0.1",
		"::1",
	})

	database := db.Connect()

	err := database.AutoMigrate(&model.Book{})
	if err != nil {
		panic(err)
	}

	healthHandler := handler.NewHealthHandler()
	healthHandler.RegisterRoutes(e)

	e.Run(":8080")
}
