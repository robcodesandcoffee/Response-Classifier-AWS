from __future__ import annotations
import aws_cdk as cdk
from constructs import Construct


class InferenceApiStack(cdk.Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Resources will be added here in later steps.
        pass
