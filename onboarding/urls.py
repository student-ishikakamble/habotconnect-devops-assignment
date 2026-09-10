from django.urls import path

from .views import StudentOnboardingCreateView

urlpatterns = [
    path(
        "students/onboarding/",
        StudentOnboardingCreateView.as_view(),
        name="student-onboarding",
    ),
]
