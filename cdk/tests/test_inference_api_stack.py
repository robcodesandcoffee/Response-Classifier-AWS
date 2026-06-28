"""Smoke test — the stack should synthesize cleanly with no resources defined yet."""

import aws_cdk as cdk
from aws_cdk import assertions

from stacks.inference_api_stack import InferenceApiStack


def test_stack_synthesizes():
    app = cdk.App()
    stack = InferenceApiStack(app, "TestStack")
    # If synth fails, this raises and the test fails.
    template = assertions.Template.from_stack(stack)
    assert template is not None
