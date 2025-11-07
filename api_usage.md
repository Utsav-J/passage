# BookMate API Usage Guide

This guide explains how to integrate the BookMate backend into a frontend app (e.g., Flutter EPUB reader). It covers authentication, data models, and all available endpoints with example requests/responses.

- Base URL: `http://localhost:8000`
- API Docs: `http://localhost:8000/docs` (Swagger) and `http://localhost:8000/redoc`
- Auth: Bearer JWT in `Authorization` header

### Remote Testing with ngrok

- Install dependencies (`uv sync` or `pip install -e .`), ensuring `pyngrok` is available.
- Set your auth token (recommended): `setx NGROK_AUTHTOKEN "<token>"` (use `export` on macOS/Linux).
- Optional region override: `setx NGROK_REGION eu`
- Launch the server with tunnelling:
  ```bash
  uv run python scripts/run_with_ngrok.py
  ```
- The script prints a public HTTPS URL you can share with mobile/web clients during development.

## Authentication

All protected endpoints require a Bearer token:

```
Authorization: Bearer <access_token>
```

### Register
- Method: `POST`
- Path: `/auth/register`
- Notes:
  - `profile_image_url` is optional. Use one of the frontend’s predefined avatar keys (e.g., `"avatar_space_cat"`). Pass `null` or omit to leave it unset.
- Body:
```json
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "StrongP@ssw0rd",
  "profile_image_url": "avatar_space_cat"
}
```
- Response 201:
```json
{
  "id": 1,
  "username": "alice",
  "email": "alice@example.com",
  "profile_image_url": "avatar_space_cat",
  "created_at": "2025-11-07T12:00:00.000000"
}
```
- cURL:
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@example.com","password":"StrongP@ssw0rd","profile_image_url":"avatar_space_cat"}'
```

### Login
- Method: `POST`
- Path: `/auth/login`
- Form fields (x-www-form-urlencoded):
  - `username`: email **or** username (both are accepted)
  - `password`: user password
- Response 200:
```json
{
  "access_token": "<jwt>",
  "token_type": "bearer"
}
```
- cURL:
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice@example.com&password=StrongP@ssw0rd"
```

### Current User
- Method: `GET`
- Path: `/auth/me`
- Headers: `Authorization: Bearer <token>`
- Response 200:
```json
{
  "id": 1,
  "username": "alice",
  "email": "alice@example.com",
  "profile_image_url": "avatar_space_cat",
  "created_at": "2025-11-07T12:00:00.000000"
}
```
- cURL:
```bash
curl http://localhost:8000/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

## Users

### Search Users
- Method: `GET`
- Path: `/users/search?query=<text>`
- Headers: `Authorization`
- Response 200: array of users
```json
[
  {
    "id": 2,
    "username": "bob",
    "email": "bob@example.com",
    "profile_image_url": null,
    "created_at": "2025-11-07T12:05:00.000000"
  }
]
```
- cURL:
```bash
curl "http://localhost:8000/users/search?query=bob" \
  -H "Authorization: Bearer $TOKEN"
```

## Books

Books store only metadata (no EPUB file). Fields:
- `title` (string, required)
- `author` (string, required)
- `cover_image_url` (string, optional)
- `progress` (number, default 0.0, e.g., reading progress)

### Get My Books
- Method: `GET`
- Path: `/books/my`
- Headers: `Authorization`
- Response 200:
```json
[
  {
    "id": 10,
    "title": "The Hobbit",
    "author": "J.R.R. Tolkien",
    "cover_image_url": "https://.../hobbit.jpg",
    "owner_id": 1,
    "progress": 0.25,
    "created_at": "2025-11-07T12:10:00.000000"
  }
]
```
- cURL:
```bash
curl http://localhost:8000/books/my \
  -H "Authorization: Bearer $TOKEN"
```

### Add Book
- Method: `POST`
- Path: `/books/add`
- Headers: `Authorization`, `Content-Type: application/json`
- Body:
```json
{
  "title": "The Hobbit",
  "author": "J.R.R. Tolkien",
  "cover_image_url": "https://.../hobbit.jpg",
  "progress": 0.0
}
```
- Response 201:
```json
{
  "id": 10,
  "title": "The Hobbit",
  "author": "J.R.R. Tolkien",
  "cover_image_url": "https://.../hobbit.jpg",
  "owner_id": 1,
  "progress": 0.0,
  "created_at": "2025-11-07T12:10:00.000000"
}
```
- cURL:
```bash
curl -X POST http://localhost:8000/books/add \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"The Hobbit","author":"J.R.R. Tolkien","cover_image_url":"https://.../hobbit.jpg","progress":0.0}'
```

### Delete Book
- Method: `DELETE`
- Path: `/books/{book_id}`
- Headers: `Authorization`
- Response 204: no content
- Response 404: if not found or not owned by the user
- cURL:
```bash
curl -X DELETE http://localhost:8000/books/10 \
  -H "Authorization: Bearer $TOKEN"
```

## Mates (Friends)

### List Accepted Mates
- Method: `GET`
- Path: `/mates`
- Headers: `Authorization`
- Response 200:
```json
[
  {
    "id": 3,
    "user_id": 1,
    "mate_id": 2,
    "status": "accepted",
    "created_at": "2025-11-07T12:15:00.000000",
    "mate": {
      "id": 2,
      "username": "bob",
      "email": "bob@example.com",
      "profile_image_url": null,
      "created_at": "2025-11-07T12:05:00.000000"
    }
  }
]
```
- cURL:
```bash
curl http://localhost:8000/mates \
  -H "Authorization: Bearer $TOKEN"
```

### Send Mate Request
- Method: `POST`
- Path: `/mates/add/{username}`
- Headers: `Authorization`
- Response 201: created (request in pending state)
- cURL:
```bash
curl -X POST http://localhost:8000/mates/add/bob \
  -H "Authorization: Bearer $TOKEN"
```

### Get Incoming Mate Requests
- Method: `GET`
- Path: `/mates/requests`
- Headers: `Authorization`
- Response 200: array of pending requests
```json
[
  {
    "id": 4,
    "user_id": 2,
    "mate_id": 1,
    "status": "pending",
    "created_at": "2025-11-07T12:20:00.000000",
    "user": {
      "id": 2,
      "username": "bob",
      "email": "bob@example.com",
      "profile_image_url": null,
      "created_at": "2025-11-07T12:05:00.000000"
    }
  }
]
```
- cURL:
```bash
curl http://localhost:8000/mates/requests \
  -H "Authorization: Bearer $TOKEN"
```

### Accept Mate Request
- Method: `POST`
- Path: `/mates/accept/{username}`
- Headers: `Authorization`
- Response 200
- cURL:
```bash
curl -X POST http://localhost:8000/mates/accept/bob \
  -H "Authorization: Bearer $TOKEN"
```

### Reject Mate Request
- Method: `POST`
- Path: `/mates/reject/{username}`
- Headers: `Authorization`
- Response 200
- cURL:
```bash
curl -X POST http://localhost:8000/mates/reject/bob \
  -H "Authorization: Bearer $TOKEN"
```

### Remove Mate
- Method: `DELETE`
- Path: `/mates/remove/{username}`
- Headers: `Authorization`
- Response 204
- cURL:
```bash
curl -X DELETE http://localhost:8000/mates/remove/bob \
  -H "Authorization: Bearer $TOKEN"
```

## Snippets (Share quotes/notes)

Snippets are short text shares between mates tied to a book.

### Send Snippet
- Method: `POST`
- Path: `/snippets/send`
- Headers: `Authorization`, `Content-Type: application/json`
- Body:
```json
{
  "mate_id": 2,
  "book_id": 10,
  "text": "In a hole in the ground there lived a hobbit.",
  "note": "Opening line"
}
```
- Response 201:
```json
{
  "id": 55,
  "sender_id": 1,
  "receiver_id": 2,
  "book_id": 10,
  "text": "In a hole in the ground there lived a hobbit.",
  "note": "Opening line",
  "created_at": "2025-11-07T12:20:00.000000",
  "sender": {
    "id": 1,
    "username": "alice",
    "email": "alice@example.com",
    "profile_image_url": "avatar_space_cat",
    "created_at": "2025-11-07T12:00:00.000000"
  },
  "receiver": {
    "id": 2,
    "username": "bob",
    "email": "bob@example.com",
    "profile_image_url": null,
    "created_at": "2025-11-07T12:05:00.000000"
  },
  "book": {
    "id": 10,
    "title": "The Hobbit",
    "author": "J.R.R. Tolkien",
    "cover_image_url": "https://.../hobbit.jpg",
    "owner_id": 1,
    "progress": 0.0,
    "created_at": "2025-11-07T12:10:00.000000"
  }
}
```
- cURL:
```bash
curl -X POST http://localhost:8000/snippets/send \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mate_id":2,"book_id":10,"text":"In a hole in the ground there lived a hobbit.","note":"Opening line"}'
```

### Get Received Snippets
- Method: `GET`
- Path: `/snippets/received`
- Headers: `Authorization`
- Response 200: array of `SnippetResponse` (as above)
- cURL:
```bash
curl http://localhost:8000/snippets/received \
  -H "Authorization: Bearer $TOKEN"
```

### Get Sent Snippets
- Method: `GET`
- Path: `/snippets/sent`
- Headers: `Authorization`
- Response 200: array of `SnippetResponse`
- cURL:
```bash
curl http://localhost:8000/snippets/sent \
  -H "Authorization: Bearer $TOKEN"
```

### Delete Snippet
- Method: `DELETE`
- Path: `/snippets/{snippet_id}`
- Headers: `Authorization`
- Response 204
- cURL:
```bash
curl -X DELETE http://localhost:8000/snippets/55 \
  -H "Authorization: Bearer $TOKEN"
```

## Error Handling
- `401 Unauthorized`: missing/invalid token
- `404 Not Found`: resource not found or not owned (e.g., deleting another user’s book)
- Validation errors: `422 Unprocessable Entity` (bad payloads)

## Integration Notes
- Access tokens do not expire automatically; users stay signed in until they explicitly log out in the client.
- Logout is purely client-managed right now—delete the stored token to sign a user out (backend does not track sessions or provide token revocation).
- CORS is enabled for all origins in development. Lock this down in production.
- SQLite is used for local dev. Use Alembic migrations to update schema.
- Books do NOT store any EPUB file or content—only metadata (`title`, `author`, optional `cover_image_url`, `progress`).

## Running Locally
```bash
uvicorn app.main:app --reload
```
Swagger UI: `http://localhost:8000/docs`


