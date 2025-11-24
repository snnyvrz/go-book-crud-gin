package handler

import "github.com/google/uuid"

type AuthorResponse struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}
