import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django_otp import devices_for_user
from django_otp.plugins.otp_static.models import StaticDevice, StaticToken


REQUIRED_ENV_VARS = (
    "DJANGO_ADMIN_USERNAME",
    "DJANGO_ADMIN_PASSWORD",
    "DJANGO_ADMIN_OTP_TOKEN",
)


class Command(BaseCommand):
    """
    Idempotently bootstrap the initial admin superuser + a static OTP
    device, from DJANGO_ADMIN_* environment variables (sourced from
    Secrets Manager via the ECS task's `secrets` block - never passed
    as plaintext containerOverrides).

    Safe to run on every deploy:
      - if the user already exists, its password is left untouched
        (so it won't clobber a password the admin changed later)
      - if the user already has ANY confirmed OTP device (static or
        TOTP), OTP setup is left untouched entirely - this prevents
        the bootstrap secret from acting as a permanent backdoor once
        a real TOTP device has been registered via the admin UI
      - only while no confirmed device exists at all does this command
        keep (re)issuing the static bootstrap token, as a safety net
        against a lockout before TOTP has ever been set up

    The static OTP token is a single-use bootstrap credential by
    django-otp design. It exists only to get the admin through the
    first login - a real TOTP device must be registered via the
    admin UI immediately after, which permanently retires this
    bootstrap path.
    """

    help = "Idempotently bootstrap the initial Django admin superuser and static OTP token."

    def handle(self, *args, **options):
        missing = [name for name in REQUIRED_ENV_VARS if not os.environ.get(name)]
        if missing:
            raise CommandError(
                f"Missing required environment variable(s): {', '.join(missing)}"
            )

        username = os.environ["DJANGO_ADMIN_USERNAME"]
        email = os.environ.get("DJANGO_ADMIN_EMAIL", "")
        password = os.environ["DJANGO_ADMIN_PASSWORD"]
        otp_token = os.environ["DJANGO_ADMIN_OTP_TOKEN"]

        User = get_user_model()

        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                "email": email,
                "is_staff": True,
                "is_superuser": True,
            },
        )

        if created:
            user.set_password(password)
            user.save()
            self.stdout.write(self.style.SUCCESS(f"Created superuser '{username}'."))
        else:
            self.stdout.write(
                f"Superuser '{username}' already exists - leaving password untouched."
            )

        has_any_device = any(devices_for_user(user, confirmed=True))

        if has_any_device:
            self.stdout.write(
                "User already has a confirmed OTP device - "
                "leaving OTP configuration untouched."
            )
        else:
            device, _ = StaticDevice.objects.get_or_create(user=user, name="bootstrap")
            device.token_set.all().delete()
            StaticToken.objects.create(device=device, token=otp_token)
            self.stdout.write(
                self.style.SUCCESS(
                    "Static OTP token configured. This is single-use - log in once, "
                    "then register a real TOTP device via the admin UI immediately."
                )
            )
