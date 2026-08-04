from django.urls import path
from .views import (
    CourseListView, CourseDetailView, CompleteLessonView, UserEnrolledCoursesView
)

urlpatterns = [
    path('', CourseListView.as_view(), name='courses_list'),
    path('<int:pk>/', CourseDetailView.as_view(), name='course_detail'),
    path('lessons/<int:lesson_id>/complete/', CompleteLessonView.as_view(), name='complete_lesson'),
    path('enrolled/', UserEnrolledCoursesView.as_view(), name='enrolled_courses'),
]
