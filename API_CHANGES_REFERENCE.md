# API Endpoint Changes - Quick Reference

## 🆕 New Endpoints Added

### Update Post
```http
PUT /api/v1/community/posts/{post_id}
```

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body (at least one field required):**
```json
{
  "content": "Updated post content",
  "image_url": "https://example.com/image.jpg"
}
```

**Success Response (200):**
```json
{
  "message": "Post updated successfully.",
  "post": {
    "id": "...",
    "user_id": "...",
    "content": "Updated post content",
    "image_url": "https://example.com/image.jpg",
    ...
  }
}
```

**Error Responses:**
- `403` - Not the post owner
- `404` - Post not found
- `400` - No fields provided

---

### Update Comment
```http
PUT /api/v1/community/comments/{comment_id}
```

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "content": "Updated comment text"
}
```

**Success Response (200):**
```json
{
  "message": "Comment updated successfully.",
  "comment": {
    "id": "...",
    "user_id": "...",
    "content": "Updated comment text",
    ...
  }
}
```

**Error Responses:**
- `403` - Not the comment owner
- `404` - Comment not found
- `400` - Empty content

---

## 🔄 Modified Endpoints

### Get Posts Feed
```http
GET /api/v1/community/posts?sort={sort}&limit={limit}&offset={offset}
```

**Changes:**
- `sort` parameter now validated with pattern: `latest` or `trending` only
- Invalid values return `422 Validation Error`

**Valid Values:**
- `sort=latest` (default)
- `sort=trending`

---

## ❌ Removed Endpoints

The following endpoint was removed (duplicate):
- ~~`GET /api/v1/community/comments?post_id={post_id}`~~

**Use instead:**
- `GET /api/v1/community/comments/{post_id}`

---

## 🔒 Authorization Rules

All community endpoints require authentication via JWT token in the `Authorization` header.

**Ownership Requirements:**
- **Update Post:** Must be the post creator
- **Update Comment:** Must be the comment creator
- **Vote:** Any authenticated user
- **Create Post/Comment:** Any authenticated user
- **Read Posts/Comments:** Any authenticated user

---

## 📝 Example Usage in Flutter

### Update a Post
```dart
Future<void> updatePost(String postId, String newContent) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiConstants.pythonBaseUrl}/community/posts/$postId'),
      headers: await _buildHeaders(),
      body: jsonEncode({'content': newContent}),
    );
    
    if (response.statusCode == 200) {
      print('Post updated successfully');
    } else {
      throw Exception('Failed to update post');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Update a Comment
```dart
Future<void> updateComment(String commentId, String newContent) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiConstants.pythonBaseUrl}/community/comments/$commentId'),
      headers: await _buildHeaders(),
      body: jsonEncode({'content': newContent}),
    );
    
    if (response.statusCode == 200) {
      print('Comment updated successfully');
    } else {
      throw Exception('Failed to update comment');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 🧪 Testing with cURL

### Test Update Post
```bash
curl -X PUT http://localhost:8001/api/v1/community/posts/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "New content here"}'
```

### Test Update Comment
```bash
curl -X PUT http://localhost:8001/api/v1/community/comments/550e8400-e29b-41d4-a716-446655440001 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Updated comment"}'
```

### Test Invalid Sort Parameter
```bash
curl "http://localhost:8001/api/v1/community/posts?sort=invalid"
# Expected: 422 Validation Error
```

### Test Valid Sort Parameter
```bash
curl "http://localhost:8001/api/v1/community/posts?sort=trending"
# Expected: 200 OK with posts
```

---

## 📊 Standardized Error Format

All errors now follow this format:

```json
{
  "error": "Human-readable error message",
  "status_code": 400,
  "details": [...] // Optional, for validation errors
}
```

**Common Status Codes:**
- `200` - Success
- `400` - Bad Request (validation failed)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `422` - Validation Error (FastAPI schema validation)
- `500` - Internal Server Error

---

This document complements the main `BACKEND_FIXES_SUMMARY.md` file.
