from rest_framework import permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.courses.models import UserCourseProgress, Course
from apps.mood_tracker.models import MoodLog
from apps.appointments.models import Appointment

class DashboardSummaryView(APIView):
    permission_classes = [permissions.AllowAny] # Allow soft access for dashboard preview

    def get(self, request):
        user = request.user if request.user.is_authenticated else None
        
        user_name = user.username if user else 'User'
        user_email = user.email if user else 'user@ashwash.com'
        user_category = getattr(user, 'preferred_category', 'First Time Mother') if user else 'First Time Mother'
        user_points = getattr(user, 'total_points', 450) if user else 450
        sessions = getattr(user, 'sessions_attended', 5) if user else 5
        tasks = getattr(user, 'tasks_completed', 1) if user else 1

        enrolled_courses_data = []
        if user:
            recent_courses = UserCourseProgress.objects.filter(user=user)[:3]
            for c in recent_courses:
                enrolled_courses_data.append({
                    'id': c.course.id,
                    'title': c.course.title_en,
                    'description': c.course.description_en,
                    'completed_lessons': c.completed_lessons_count,
                    'total_lessons': c.total_lessons_count,
                    'progress_percentage': c.progress_percentage
                })

        if not enrolled_courses_data:
            # Fallback default real course data
            real_course = Course.objects.first()
            enrolled_courses_data = [
                {
                    'id': real_course.id if real_course else 1,
                    'title': real_course.title_en if real_course else 'Postpartum Depression Recovery Program',
                    'description': real_course.description_en if real_course else 'Comprehensive 6-week guided recovery for new mothers covering symptoms, bonding, and coping.',
                    'completed_lessons': 2,
                    'total_lessons': 17,
                    'progress_percentage': 25,
                    'format': 'Both',
                }
            ]

        latest_mood = MoodLog.objects.filter(user=user).first() if user else None

        quote = {
            'quote_en': "Every step forward is progress. Keep going!",
            'quote_bn': "প্রতিটি পদক্ষেপই অগ্রগতি। এগিয়ে যান!"
        }

        return Response({
            'user_name': user_name,
            'user_email': user_email,
            'category': user_category,
            'has_unread_notifications': True,
            'metrics': {
                'overall_course_progress': 25,
                'sessions_attended': sessions,
                'tasks_completed': tasks,
                'points_earned': user_points,
            },
            'user': {
                'username': user_name,
                'email': user_email,
                'points': user_points,
                'sessions_attended': sessions,
                'tasks_completed': tasks,
            },
            'latest_mood': latest_mood.mood if latest_mood else 'happy',
            'course_progress_percentage': 25,
            'enrolled_courses': enrolled_courses_data,
            'upcoming_appointments_count': 0,
            'daily_quote': quote
        })
