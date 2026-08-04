from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Post, Comment, Like, Report
from .serializers import PostSerializer, CommentSerializer

class PostListCreateView(generics.ListCreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = Post.objects.all()
        tag = self.request.query_params.get('tag')
        if tag and tag != 'All':
            queryset = queryset.filter(tag=tag)
        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        if user.role in ['SPECIALIST', 'DOCTOR']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only patients can create community posts. Specialists can reply to posts with their doctor badge.')

        is_anon = serializer.validated_data.get('is_anonymous', True)
        if is_anon:
            alias = 'Anonymous Member'
        else:
            full_name = f"{user.first_name} {user.last_name}".strip()
            alias = full_name if full_name else user.username
        serializer.save(author=user, is_anonymous=is_anon, author_alias=alias)

class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.author == request.user or request.user.is_staff

class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]

    def perform_update(self, serializer):
        is_anon = serializer.validated_data.get('is_anonymous', serializer.instance.is_anonymous)
        if is_anon:
            alias = 'Anonymous Member'
        else:
            full_name = f"{self.request.user.first_name} {self.request.user.last_name}".strip()
            alias = full_name if full_name else self.request.user.username
        serializer.save(author_alias=alias)

class LikePostView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        try:
            post = Post.objects.get(id=post_id)
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)

        like, created = Like.objects.get_or_create(post=post, user=request.user)
        if not created:
            like.delete()
            post.likes_count = max(0, post.likes_count - 1)
            liked = False
        else:
            post.likes_count += 1
            liked = True
            # Trigger 6: Notify ONLY the post author when someone likes their post
            if post.author and post.author != request.user:
                try:
                    from apps.notifications.views import send_notification
                    sender_name = request.user.full_name if (hasattr(request.user, 'full_name') and request.user.full_name) else request.user.username
                    send_notification(
                        recipient=post.author,
                        sender=request.user,
                        title_en=f"New Reaction on Your Post ❤️",
                        title_bn=f"আপনার পোস্টে রিয়েক্ট দিয়েছেন ❤️",
                        message_en=f"{sender_name} liked your community post.",
                        message_bn=f"{sender_name} আপনার কমিউনিটি পোস্টে লাইক দিয়েছেন।",
                        category='COMMUNITY'
                    )
                except Exception:
                    pass

        post.save()

        return Response({'liked': liked, 'likes_count': post.likes_count})

class AddCommentView(generics.CreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = request.user
        is_specialist = user.role in ['DOCTOR', 'ADMIN', 'SPECIALIST'] or user.is_staff
        if not is_specialist:
            return Response(
                {'detail': 'Only verified mental health specialists and doctors can comment on community posts.'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().post(request, *args, **kwargs)

    def perform_create(self, serializer):
        post_id = self.kwargs['post_id']
        post = Post.objects.get(id=post_id)
        author_name = f"Dr. {self.request.user.first_name or self.request.user.username} (Specialist)"
        serializer.save(post=post, author=self.request.user, author_alias=author_name)
        post.comments_count += 1
        post.save()

        # Trigger 6: Notify ONLY the post owner when someone comments on their post
        if post.author and post.author != self.request.user:
            try:
                from apps.notifications.views import send_notification
                send_notification(
                    recipient=post.author,
                    sender=self.request.user,
                    title_en=f"New Reply on Your Post 💬",
                    title_bn=f"আপনার পোস্টে নতুন উত্তর 💬",
                    message_en=f"{author_name} replied to your community post.",
                    message_bn=f"{author_name} আপনার কমিউনিটি পোস্টে মন্তব্য করেছেন।",
                    category='COMMUNITY'
                )
            except Exception:
                pass

class ReportPostView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        try:
            post = Post.objects.get(id=post_id)
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)

        reason = request.data.get('reason', 'Inappropriate content')
        Report.objects.create(post=post, user=request.user, reason=reason)
        return Response({'message': 'Report submitted successfully'}, status=status.HTTP_201_CREATED)
