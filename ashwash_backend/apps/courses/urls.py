from django.urls import path
from .views import (
    CourseListView, CourseDetailView, CompleteLessonView, UserEnrolledCoursesView, EnrollCourseView
)

urlpatterns = [
    path('', CourseListView.as_view(), name='courses_list'),
    path('<int:pk>/', CourseDetailView.as_view(), name='course_detail'),
    path('<int:course_id>/enroll/', EnrollCourseView.as_view(), name='enroll_course'),
    path('lessons/<int:lesson_id>/complete/', CompleteLessonView.as_view(), name='complete_lesson'),
    path('enrolled/', UserEnrolledCoursesView.as_view(), name='enrolled_courses'),
]

