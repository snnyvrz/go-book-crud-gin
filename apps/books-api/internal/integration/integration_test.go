//go:build integration
// +build integration

package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/snnyvrz/shelfshare/apps/books-api/internal/handler"
	"github.com/snnyvrz/shelfshare/apps/books-api/internal/model"
	"github.com/snnyvrz/shelfshare/apps/books-api/internal/repository"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var (
	testDB     *gorm.DB
	testRouter *gin.Engine
)

func TestMain(m *testing.M) {
	DBHost := os.Getenv("DB_HOST")
	DBPort := os.Getenv("DB_PORT")
	DBUser := os.Getenv("DB_USER")
	DBPass := os.Getenv("DB_PASS")
	DBName := os.Getenv("DB_NAME")
	DBSSLMode := "disable"
	TZ := os.Getenv("TZ")

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=%s",
		DBHost,
		DBUser,
		DBPass,
		DBName,
		DBPort,
		DBSSLMode,
		TZ,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("failed to connect to test database: " + err.Error())
	}
	testDB = db

	if err := db.AutoMigrate(&model.Author{}, &model.Book{}); err != nil {
		panic("failed to migrate: " + err.Error())
	}

	gin.SetMode(gin.TestMode)
	r := gin.Default()

	authorRepo := repository.NewAuthorRepository(db)
	bookRepo := repository.NewGormBookRepository(db)

	authorHandler := handler.NewAuthorHandler(authorRepo)
	bookHandler := handler.NewBookHandler(bookRepo)

	api := r.Group("/api")
	{
		authorHandler.RegisterRoutes(api.Group(""))
		bookHandler.RegisterRoutes(api.Group(""))
	}

	testRouter = r

	code := m.Run()
	os.Exit(code)
}

func resetDB(t *testing.T) {
	t.Helper()
	sqlDB, err := testDB.DB()
	if err != nil {
		t.Fatalf("get sql.DB failed: %v", err)
	}
	_, err = sqlDB.Exec("TRUNCATE TABLE books, authors RESTART IDENTITY CASCADE;")
	if err != nil {
		t.Fatalf("truncate failed: %v", err)
	}
}

func newTestServer() *httptest.Server {
	return httptest.NewServer(testRouter)
}

func TestCreateBookAndFetchIt_BackendIntegration(t *testing.T) {
	resetDB(t)

	srv := newTestServer()
	defer srv.Close()

	client := srv.Client()

	authorReq := map[string]string{
		"name": "Robert C. Martin",
		"bio":  "Uncle Bob",
	}
	body, _ := json.Marshal(authorReq)
	resp, err := client.Post(srv.URL+"/api/authors", "application/json", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("failed to create author: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}
	var createdAuthor map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&createdAuthor)
	resp.Body.Close()

	authorID, _ := createdAuthor["id"].(string)

	bookReq := map[string]any{
		"title":       "Clean Code",
		"author_id":   authorID,
		"description": "A Handbook of Agile Software Craftsmanship",
	}
	body, _ = json.Marshal(bookReq)
	resp, err = client.Post(srv.URL+"/api/books", "application/json", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("failed to create book: %v", err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}
	var createdBook map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&createdBook)
	resp.Body.Close()

	bookID, _ := createdBook["id"].(string)

	resp, err = client.Get(srv.URL + "/api/books/" + bookID)
	if err != nil {
		t.Fatalf("failed to get book: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	var fetched map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&fetched)

	if fetched["title"] != "Clean Code" {
		t.Errorf("expected title=Clean Code, got %v", fetched["title"])
	}

	author, ok := fetched["author"].(map[string]any)
	if !ok {
		t.Fatalf("expected 'author' object, got %T (%v)", fetched["author"], fetched["author"])
	}
	if author["id"] != authorID {
		t.Errorf("expected author.id=%s, got %v", authorID, author["id"])
	}
}
