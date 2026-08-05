from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Course, Lesson, UserCourseProgress, UserLessonProgress
from .serializers import CourseSerializer, UserCourseProgressSerializer, LessonSerializer

def save_lessons_for_course(course, lessons_data):
    if not lessons_data:
        return
    from .models import Module, Lesson
    module, _ = Module.objects.get_or_create(
        course=course,
        order=1,
        defaults={
            'title_en': f"Module 1 - {course.title_en}",
            'title_bn': f"মডিউল ১ - {course.title_bn}",
        }
    )
    for idx, l in enumerate(lessons_data, 1):
        if isinstance(l, dict):
            l_title = l.get('title') or l.get('title_en') or f'Lesson {idx}'
            l_type = l.get('type') or 'video'
            l_file = l.get('file') or l.get('url') or l.get('video_url') or l.get('content_url') or ''
            
            Lesson.objects.create(
                module=module,
                title_en=l_title,
                title_bn=l_title,
                content_en=l_type,
                content_bn=l_type,
                video_url=str(l_file) if str(l_file).startswith('http') else '',
                order=idx
            )

class CourseListView(generics.ListCreateAPIView):
    serializer_class = CourseSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = Course.objects.all()
        category_id = self.request.query_params.get('category_id')
        instructor_id = self.request.query_params.get('instructor_id') or self.request.query_params.get('instructor')
        search = self.request.query_params.get('search')
        show_all = self.request.query_params.get('show_all')

        if not show_all and not instructor_id:
            token = self.request.headers.get('Authorization', '').replace('Bearer ', '').strip()
            user = self.request.user
            if not user.is_authenticated and token:
                try:
                    from rest_framework_simplejwt.tokens import AccessToken
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    validated_token = AccessToken(token)
                    user_id = validated_token['user_id']
                    user = User.objects.get(id=user_id)
                except Exception:
                    pass

            if user and user.is_authenticated and (user.role in ['SPECIALIST', 'DOCTOR']):
                queryset = queryset.filter(instructor=user)
            elif not (user and user.is_authenticated and (user.is_staff or user.role == 'ADMIN')):
                queryset = queryset.filter(is_approved=True)

        if category_id:
            queryset = queryset.filter(category_id=category_id)
        if instructor_id:
            queryset = queryset.filter(instructor_id=instructor_id)
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(title_en__icontains=search) | 
                Q(title_bn__icontains=search) | 
                Q(description_en__icontains=search) | 
                Q(description_bn__icontains=search)
            )

        return queryset

    def perform_create(self, serializer):
        token = self.request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = self.request.user
        if not user.is_authenticated and token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                from django.contrib.auth import get_user_model
                User = get_user_model()
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user or not user.is_authenticated:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = User.objects.filter(role='SPECIALIST').first()

        media_file = self.request.FILES.get('media_file')
        media_url = self.request.data.get('media_url', '')

        is_appr = False
        if user and (user.is_staff or getattr(user, 'role', '') == 'ADMIN'):
            is_appr = True

        course = serializer.save(
            instructor=user,
            media_file=media_file,
            media_url=media_url,
            is_approved=is_appr
        )
        lessons_data = self.request.data.get('lessons', [])
        save_lessons_for_course(course, lessons_data)

class CourseDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Course.objects.all()
    serializer_class = CourseSerializer
    permission_classes = [permissions.AllowAny]

    def perform_update(self, serializer):
        course = serializer.save()
        lessons_data = self.request.data.get('lessons', [])
        if lessons_data:
            from .models import Lesson
            Lesson.objects.filter(module__course=course).delete()
            save_lessons_for_course(course, lessons_data)

        # Trigger 2: Notify ONLY patients enrolled in this specific course
        try:
            from apps.notifications.views import send_notification
            enrolled_progresses = UserCourseProgress.objects.filter(course=course)
            for prog in enrolled_progresses:
                send_notification(
                    recipient=prog.user,
                    sender=self.request.user if self.request.user.is_authenticated else None,
                    title_en=f"Enrolled Course Updated: {course.title_en} 🔔",
                    title_bn=f"আপনার এনরোল করা কোর্স আপডেট: {course.title_bn} 🔔",
                    message_en=f"New content and lessons were updated in '{course.title_en}'.",
                    message_bn=f"আপনার এনরোল করা কোর্স '{course.title_bn}'-এ নতুন লেসন ও তথ্য যুক্ত হয়েছে।",
                    category='COURSE'
                )
        except Exception:
            pass

class CompleteLessonView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, lesson_id):
        try:
            lesson = Lesson.objects.get(id=lesson_id)
        except Lesson.DoesNotExist:
            return Response({'error': 'Lesson not found'}, status=status.HTTP_404_NOT_FOUND)

        UserLessonProgress.objects.get_or_create(user=request.user, lesson=lesson, defaults={'is_completed': True})

        course = lesson.module.course
        all_lessons_count = Lesson.objects.filter(module__course=course).count() or 1
        completed_count = UserLessonProgress.objects.filter(
            user=request.user, lesson__module__course=course, is_completed=True
        ).count()

        pct = int((completed_count / all_lessons_count) * 100)
        progress, _ = UserCourseProgress.objects.get_or_create(
            user=request.user, course=course
        )
        progress.completed_lessons_count = completed_count
        progress.total_lessons_count = all_lessons_count
        progress.progress_percentage = pct
        progress.is_completed = (pct >= 100)
        progress.save()

        # Trigger 3: Notify ONLY the specialist (course owner) when patient submits homework/lesson task
        try:
            if course.instructor and course.instructor != request.user:
                from apps.notifications.views import send_notification
                patient_name = request.user.full_name if (hasattr(request.user, 'full_name') and request.user.full_name) else request.user.username
                send_notification(
                    recipient=course.instructor,
                    sender=request.user,
                    title_en=f"Homework Task Submitted by {patient_name} 📝",
                    title_bn=f"{patient_name} কোর্স টাস্ক জমা দিয়েছেন 📝",
                    message_en=f"Patient {patient_name} submitted homework task in '{course.title_en}'.",
                    message_bn=f"পেশেন্ট {patient_name} আপনার কোর্স '{course.title_bn}'-এর টাস্ক সাবমিট করেছেন।",
                    category='COURSE'
                )
        except Exception:
            pass

        return Response(UserCourseProgressSerializer(progress).data)

class UserEnrolledCoursesView(generics.ListAPIView):
    serializer_class = UserCourseProgressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserCourseProgress.objects.filter(user=self.request.user)
