from django.urls import path
from .views import (
    PostListCreateView, PostDetailView, LikePostView, AddCommentView, ReportPostView
)

urlpatterns = [
    path('posts/', PostListCreateView.as_view(), name='posts_list'),
    path('posts/<int:pk>/', PostDetailView.as_view(), name='post_detail'),
    path('posts/<int:post_id>/like/', LikePostView.as_view(), name='like_post'),
    path('posts/<int:post_id>/comments/', AddCommentView.as_view(), name='add_comment'),
    path('posts/<int:post_id>/report/', ReportPostView.as_view(), name='report_post'),
]
