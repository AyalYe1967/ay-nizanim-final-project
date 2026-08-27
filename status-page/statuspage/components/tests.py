from django.test import SimpleTestCase

from components.choices import ComponentStatusChoices
from components.models import Component


class ComponentModelUnitTests(SimpleTestCase):

    def test_component_default_values(self):
        component = Component(name="API")

        self.assertEqual(
            component.status,
            ComponentStatusChoices.OPERATIONAL
        )
        self.assertFalse(component.visibility)
        self.assertEqual(component.order, 1)

    def test_component_string_representation(self):
        component = Component(name="Database")

        self.assertEqual(str(component), "Database")

    def test_operational_component_colors(self):
        component = Component(
            name="API",
            status=ComponentStatusChoices.OPERATIONAL
        )

        self.assertEqual(
            component.get_status_color(),
            "bg-green-500"
        )

        self.assertEqual(
            component.get_status_text_color(),
            "text-green-500"
        )