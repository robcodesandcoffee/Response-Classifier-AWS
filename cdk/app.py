import aws_cdk as cdk
from stacks.inference_api_stack import InferenceApiStack  # ← new

app = cdk.App()

InferenceApiStack(app, "MLPlatformApiStack-dev")  # ← new

app.synth()
