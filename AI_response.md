Based on the exact architecture of your app (Flutter Frontend + FastAPI Backend + Supabase PostgreSQL/Auth), here is the complete, production-ready code to implement a 1-to-1 replica of the Instagram clone feature.

This is broken down into 3 parts: Database Schema, FastAPI Backend, and Flutter App.

Part 1: Supabase Database Schema (PostgreSQL)

Run this SQL in your Supabase SQL Editor. It uses strict relational mapping (Foreign Keys) instead of the NoSQL approach from the article, matching your architecture.

code
SQL
download
content_copy
expand_less
-- 1. Posts Table (Includes soft-delete flag)
CREATE TABLE public.posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Post Comments Table
CREATE TABLE public.post_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Post Likes (Votes) Table
CREATE TABLE public.post_likes (
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id) -- Prevents duplicate likes
);

-- 4. Set up Storage for Images
-- Go to Supabase Storage and create a public bucket named 'post_images'
Part 2: Python Backend (FastAPI)

Add this to your FastAPI application. It handles fetching the feed (using SQL JOINs), creating posts, liking, commenting, and soft deleting.

code
Python
download
content_copy
expand_less
# main.py or routers/posts.py
from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel
from supabase import create_client, Client
import os
from typing import Optional, List

router = APIRouter(prefix="/community", tags=["Community"])

# Initialize Supabase client for backend DB operations
supabase: Client = create_client(os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY"))

# Pydantic Models
class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None

class CommentCreate(BaseModel):
    content: str

# Helper to get current user from token sent by Flutter
def get_current_user_id(authorization: str = Header(...)):
    token = authorization.split(" ")[1]
    user = supabase.auth.get_user(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user.user.id

@router.get("/posts")
def get_feed():
    # Fetch active posts, join with author profiles, comments, and likes
    response = supabase.table("posts").select(
        "id, content, image_url, created_at, "
        "profiles:user_id(id, username, avatar_url), "
        "post_likes(user_id), "
        "post_comments(id, content, created_at, profiles:user_id(id, username, avatar_url))"
    ).eq("is_deleted", False).order("created_at", desc=True).execute()
    
    return {"data": response.data}

@router.post("/posts")
def create_post(post: PostCreate, user_id: str = Depends(get_current_user_id)):
    new_post = {
        "user_id": user_id,
        "content": post.content,
        "image_url": post.image_url,
        "is_deleted": False
    }
    response = supabase.table("posts").insert(new_post).execute()
    return response.data[0]

@router.delete("/posts/{post_id}")
def soft_delete_post(post_id: str, user_id: str = Depends(get_current_user_id)):
    # Soft delete: Just set is_deleted to True
    response = supabase.table("posts").update({"is_deleted": True}).eq("id", post_id).eq("user_id", user_id).execute()
    return {"message": "Post soft deleted"}

@router.post("/posts/{post_id}/like")
def toggle_like(post_id: str, user_id: str = Depends(get_current_user_id)):
    # Check if already liked
    existing = supabase.table("post_likes").select("*").eq("post_id", post_id).eq("user_id", user_id).execute()
    
    if existing.data:
        # Unlike
        supabase.table("post_likes").delete().eq("post_id", post_id).eq("user_id", user_id).execute()
        return {"status": "unliked"}
    else:
        # Like
        supabase.table("post_likes").insert({"post_id": post_id, "user_id": user_id}).execute()
        return {"status": "liked"}

@router.post("/posts/{post_id}/comments")
def add_comment(post_id: str, comment: CommentCreate, user_id: str = Depends(get_current_user_id)):
    new_comment = {
        "post_id": post_id,
        "user_id": user_id,
        "content": comment.content
    }
    response = supabase.table("post_comments").insert(new_comment).execute()
    return response.data[0]
Part 3: Flutter App (Frontend)

Here is the complete Flutter implementation matching your architecture. It uses REST API (pull-to-refresh), handles Direct Supabase Storage uploads (which was missing in your current code), and talks to your Python API.

1. Models & API Service (api_service.dart)
code
Dart
download
content_copy
expand_less
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityApiService {
  final String baseUrl = 'YOUR_FASTAPI_URL/community';
  final SupabaseClient supabase = Supabase.instance.client;

  // Helper to get auth headers for Python API
  Future<Map<String, String>> _getHeaders() async {
    final session = supabase.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session?.accessToken}',
    };
  }

  // 1. Fetch Feed (No StreamBuilder, returns standard Future)
  Future<List<dynamic>> fetchFeed() async {
    final response = await http.get(Uri.parse('$baseUrl/posts'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    throw Exception('Failed to load feed');
  }

  // 2. Upload Image Directly to Supabase Storage (The missing piece!)
  Future<String?> uploadImageToSupabase(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('post_images').upload(fileName, imageFile);
      
      // Return the public URL to send to Python
      return supabase.storage.from('post_images').getPublicUrl(fileName);
    } catch (e) {
      print("Image upload failed: $e");
      return null;
    }
  }

  // 3. Create Post
  Future<void> createPost(String content, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImageToSupabase(imageFile);
    }

    await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: await _getHeaders(),
      body: jsonEncode({'content': content, 'image_url': imageUrl}),
    );
  }

  // 4. Toggle Like
  Future<void> toggleLike(String postId) async {
    await http.post(Uri.parse('$baseUrl/posts/$postId/like'), headers: await _getHeaders());
  }

  // 5. Add Comment
  Future<void> addComment(String postId, String content) async {
    await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
      body: jsonEncode({'content': content}),
    );
  }

  // 6. Soft Delete Post
  Future<void> deletePost(String postId) async {
    await http.delete(Uri.parse('$baseUrl/posts/$postId'), headers: await _getHeaders());
  }
}
2. The Feed UI (community_screen.dart)

This implements the UI with RefreshIndicator (pull-to-refresh) and local state updates to make likes feel instant.

code
Dart
download
content_copy
expand_less
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'api_service.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityApiService _apiService = CommunityApiService();
  List<dynamic> _posts =[];
  bool _isLoading = true;
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _apiService.fetchFeed();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Handles picking image and creating a post
  Future<void> _showCreatePostModal() async {
    TextEditingController _controller = TextEditingController();
    File? _selectedImage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: 'What is happening?'),
                maxLines: 3,
              ),
              if (_selectedImage != null) Image.file(_selectedImage!, height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setModalState(() => _selectedImage = File(picked.path));
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // close modal
                      setState(() => _isLoading = true);
                      await _apiService.createPost(_controller.text, _selectedImage);
                      _loadPosts(); // Refresh feed
                    },
                    child: Text('Post'),
                  )
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community Feed')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        child: Icon(Icons.add),
      ),
      // PULL TO REFRESH IMPLEMENTATION
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  
                  // Extract relational data from JSON
                  final author = post['profiles'];
                  final likes = post['post_likes'] as List;
                  final comments = post['post_comments'] as List;
                  
                  // Check if current user liked it
                  bool isLiked = likes.any((like) => like['user_id'] == currentUserId);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(author['avatar_url'] ?? '')),
                          title: Text(author['username']),
                          subtitle: Text(timeago.format(DateTime.parse(post['created_at']))),
                          trailing: post['profiles']['id'] == currentUserId 
                              ? IconButton(
                                  icon: Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await _apiService.deletePost(post['id']);
                                    _loadPosts();
                                  },
                                )
                              : null,
                        ),
                        if (post['image_url'] != null)
                          Image.network(post['image_url'], fit: BoxFit.cover, width: double.infinity),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children:[
                                  IconButton(
                                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                                    onPressed: () {
                                      // Optimistic UI update for instant feedback
                                      setState(() {
                                        if (isLiked) {
                                          likes.removeWhere((l) => l['user_id'] == currentUserId);
                                        } else {
                                          likes.add({'user_id': currentUserId});
                                        }
                                      });
                                      _apiService.toggleLike(post['id']);
                                    },
                                  ),
                                  Text('${likes.length} likes'),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text.rich(TextSpan(children: [
                                TextSpan(text: '${author['username']} ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: post['content']),
                              ])),
                              SizedBox(height: 8),
                              Text('View all ${comments.length} comments', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
How this solves the problem specifically for your app:

Hybrid Architecture Preserved: CommunityApiService fetches the Supabase Token natively, attaches it as a Bearer token, and routes all database reads/writes through your Python FastAPI.

Missing Image Upload Fixed: It bypasses FastAPI for file streaming (which is slow) and uploads the file directly to Supabase Storage from Flutter. It then passes the returned fast-loading URL to FastAPI.

NoSQL Denormalization Removed: Replaced with standard JOIN queries in FastAPI, which is the strictly correct way to handle this on Postgres/Supabase.

No StreamBuilders: Standard Stateful widget with RefreshIndicator handles Realtime via pull-to-refresh, matching your current design requirements. Optimistic state updates (setState on Like) are used so it still feels as fast as Firebase without needing WebSockets.


































Hackathon calendar view - Monthly calendar showing hackathon dates
Team chat - In-app messaging for team members
Push notifications - Reminders for deadlines, messages
Deep linking - Share specific hackathons via URL
Report/block functionality - For inappropriate content









