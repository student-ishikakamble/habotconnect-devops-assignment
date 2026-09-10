from django.db import models


class StudentOnboarding(models.Model):
    student_name = models.CharField(max_length=100)
    email = models.EmailField(max_length=254)

    requires_learning_support = models.BooleanField()
    parent_consent = models.BooleanField()
    emergency_contact_provided = models.BooleanField()

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.student_name} - {self.email}"
