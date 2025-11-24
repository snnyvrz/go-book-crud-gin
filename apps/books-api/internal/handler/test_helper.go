package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/snnyvrz/shelfshare/apps/books-api/internal/repository"
	"gorm.io/gorm"
)

func setupRouterWithRepos(
	bookRepo repository.BookRepository,
	authorRepo repository.AuthorRepository,
) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.Default()

	bh := NewBookHandler(bookRepo)
	bh.RegisterRoutes(r.Group(""))

	ah := NewAuthorHandler(authorRepo)
	ah.RegisterRoutes(r.Group(""))

	return r
}

func setupRouter(db *gorm.DB) *gin.Engine {
	bookRepo := repository.NewGormBookRepository(db)
	authorRepo := repository.NewAuthorRepository(db)
	return setupRouterWithRepos(bookRepo, authorRepo)
}
