from django.db import models
from django.conf import settings
from apps.authentication.models import Category

class Course(models.Model):
    instructor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name='created_courses')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='courses')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    subtitle_en = models.CharField(max_length=255, blank=True, default='')
    subtitle_bn = models.CharField(max_length=255, blank=True, default='')
    description_en = models.TextField()
    description_bn = models.TextField()
    duration_weeks = models.IntegerField(default=4)
    total_tasks = models.IntegerField(default=10)
    type_label = models.CharField(max_length=50, default='Both') # e.g. Video, Audio, Both
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00) # 0 for Free
    is_free = models.BooleanField(default=True)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.9)
    thumbnail_url = models.URLField(max_length=1000, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True, null=True)
    updated_at = models.DateTimeField(auto_now=True, null=True)

    def __str__(self):
        return self.title_en

class Module(models.Model):
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='modules')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    order = models.IntegerField(default=1)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.course.title_en} - Mod {self.order}: {self.title_en}"

class Lesson(models.Model):
    module = models.ForeignKey(Module, on_delete=models.CASCADE, related_name='lessons')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    content_en = models.TextField(blank=True)
    content_bn = models.TextField(blank=True)
    video_url = models.URLField(max_length=1000, blank=True, default='')
    duration_minutes = models.IntegerField(default=15)
    order = models.IntegerField(default=1)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.module.title_en} - Lesson {self.order}: {self.title_en}"

class Assignment(models.Model):
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='assignments')
    instruction_en = models.TextField()
    instruction_bn = models.TextField()

    def __str__(self):
        return f"Assignment for {self.lesson.title_en}"

class UserCourseProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='course_progress')
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    completed_lessons_count = models.IntegerField(default=0)
    total_lessons_count = models.IntegerField(default=5)
    progress_percentage = models.IntegerField(default=0)
    is_completed = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'course')

    def __str__(self):
        return f"{self.user.username} - {self.course.title_en}: {self.progress_percentage}%"

class UserLessonProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE)
    is_completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'lesson')
