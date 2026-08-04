from rest_framework import serializers
from .models import Course, Module, Lesson, Assignment, UserCourseProgress, UserLessonProgress

class AssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Assignment
        fields = ['id', 'instruction_en', 'instruction_bn']

class LessonSerializer(serializers.ModelSerializer):
    assignments = AssignmentSerializer(many=True, read_only=True)
    type = serializers.SerializerMethodField()
    file = serializers.SerializerMethodField()

    class Meta:
        model = Lesson
        fields = ['id', 'title_en', 'title_bn', 'content_en', 'content_bn', 'video_url', 'file', 'type', 'duration_minutes', 'order', 'assignments']

    def get_type(self, obj):
        if obj.content_en and obj.content_en.lower() in ['video', 'audio', 'pdf', 'article']:
            return obj.content_en.lower()
        if obj.video_url:
            url_lower = obj.video_url.lower()
            if '.mp3' in url_lower or 'audio' in url_lower:
                return 'audio'
            if '.pdf' in url_lower or 'pdf' in url_lower:
                return 'pdf'
        return 'video'

    def get_file(self, obj):
        return obj.video_url

class ModuleSerializer(serializers.ModelSerializer):
    lessons = LessonSerializer(many=True, read_only=True)

    class Meta:
        model = Module
        fields = ['id', 'title_en', 'title_bn', 'order', 'lessons']

class CourseSerializer(serializers.ModelSerializer):
    modules = ModuleSerializer(many=True, read_only=True)
    category_name = serializers.CharField(source='category.title_en', read_only=True, allow_null=True)
    instructor_id = serializers.IntegerField(source='instructor.id', read_only=True, allow_null=True)
    instructor_details = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = [
            'id', 'instructor', 'instructor_id', 'instructor_details',
            'category', 'category_name', 'title_en', 'title_bn', 'subtitle_en', 'subtitle_bn',
            'description_en', 'description_bn', 'duration_weeks', 'total_tasks',
            'type_label', 'price', 'is_free', 'rating', 'thumbnail_url', 'created_at', 'updated_at', 'modules'
        ]

    def get_instructor_details(self, obj):
        if not obj.instructor:
            return None
        user = obj.instructor
        full_name = f"{user.first_name} {user.last_name}".strip() or user.username

        qual = "Mental Health Specialist"
        spec_title = "Clinical Psychologist"
        avatar = ""

        try:
            profile = getattr(user, 'specialist_profile', None)
            if profile:
                qual = getattr(profile, 'qualification', '') or qual
                spec_title = getattr(profile, 'specialization', '') or spec_title
                avatar = getattr(profile, 'avatar_url', '') or avatar
        except Exception:
            pass

        try:
            from apps.appointments.models import Specialist
            spec_obj = None
            if user.first_name:
                spec_obj = Specialist.objects.filter(name__icontains=user.first_name).first()
            if not spec_obj and user.username:
                spec_obj = Specialist.objects.filter(name__icontains=user.username).first()
            if spec_obj:
                if not avatar and spec_obj.avatar_url:
                    avatar = spec_obj.avatar_url
                qual = spec_obj.degree or qual
                spec_title = spec_obj.title_en or spec_title
        except Exception:
            spec_obj = None

        return {
            'id': user.id,
            'name': full_name,
            'avatar_url': avatar,
            'qualification': qual,
            'specialization': spec_title,
            'experience_years': getattr(spec_obj, 'experience_years', 5) if spec_obj else 5,
            'rating': float(getattr(spec_obj, 'rating', 4.9)) if spec_obj else 4.9,
        }

class UserCourseProgressSerializer(serializers.ModelSerializer):
    course_title_en = serializers.CharField(source='course.title_en', read_only=True)
    course_title_bn = serializers.CharField(source='course.title_bn', read_only=True)

    class Meta:
        model = UserCourseProgress
        fields = [
            'id', 'course', 'course_title_en', 'course_title_bn',
            'completed_lessons_count', 'total_lessons_count', 'progress_percentage',
            'is_completed', 'updated_at'
        ]
