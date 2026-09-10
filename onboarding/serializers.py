from rest_framework import serializers

from .dcyn import normalize_yes_no
from .models import StudentOnboarding


class StudentOnboardingSerializer(serializers.ModelSerializer):
    requires_learning_support = serializers.BooleanField()
    parent_consent = serializers.BooleanField()
    emergency_contact_provided = serializers.BooleanField()

    class Meta:
        model = StudentOnboarding
        fields = [
            "student_name",
            "email",
            "requires_learning_support",
            "parent_consent",
            "emergency_contact_provided",
            "created_at",
        ]
        read_only_fields = ["created_at"]

    def validate_student_name(self, value):
        value = value.strip()

        if not value:
            raise serializers.ValidationError("Student name must not be empty.")

        if len(value) > 100:
            raise serializers.ValidationError(
                "Student name must not exceed 100 characters."
            )

        return value

    def validate_email(self, value):
        value = value.strip().lower()

        if len(value) > 254:
            raise serializers.ValidationError("Email must not exceed 254 characters.")

        return value

    def validate(self, attrs):
        attrs["requires_learning_support"] = (
            normalize_yes_no(attrs["requires_learning_support"]) == "Yes"
        )
        attrs["parent_consent"] = normalize_yes_no(attrs["parent_consent"]) == "Yes"
        attrs["emergency_contact_provided"] = (
            normalize_yes_no(attrs["emergency_contact_provided"]) == "Yes"
        )

        return attrs
