from django.test import SimpleTestCase

from metrics.choices import MetricExpandChoices
from metrics.models import Metric, MetricPoint


class MetricModelUnitTests(SimpleTestCase):

    def test_metric_default_values(self):
        metric = Metric(
            title="CPU Usage",
            suffix="%"
        )

        self.assertFalse(metric.visibility)
        self.assertEqual(metric.order, 1)
        self.assertEqual(
            metric.expand,
            MetricExpandChoices.ON_CLICK
        )

    def test_metric_string_representation(self):
        metric = Metric(
            title="Memory Usage",
            suffix="%"
        )

        self.assertEqual(
            str(metric),
            "Memory Usage"
        )

    def test_metric_should_expand_when_always_enabled(self):
        metric = Metric(
            title="CPU Usage",
            suffix="%",
            expand=MetricExpandChoices.ALWAYS
        )

        self.assertEqual(
            metric.should_expand,
            "true"
        )

    def test_metric_point_string_representation(self):
        metric = Metric(
            title="CPU Usage",
            suffix="%"
        )

        point = MetricPoint(
            metric=metric,
            value=42.5
        )

        self.assertEqual(
            str(point),
            "42.5"
        )